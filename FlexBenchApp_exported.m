classdef FlexBenchApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        FlexBenchAppUIFigure            matlab.ui.Figure
        Image                           matlab.ui.control.Image
        FlexBenchLabel                  matlab.ui.control.Label
        ResistancePanel                 matlab.ui.container.Panel
        ResistanceTestButton            matlab.ui.control.StateButton
        ConnectPanel                    matlab.ui.container.Panel
        ConnectLamp                     matlab.ui.control.Lamp
        PortDropDown                    matlab.ui.control.DropDown
        BaudRateDropDown                matlab.ui.control.DropDown
        ConnectButton                   matlab.ui.control.Button
        TestPanel                       matlab.ui.container.Panel
        StartTestButton                 matlab.ui.control.StateButton
        SetPanel                        matlab.ui.container.Panel
        SetHeightsButton                matlab.ui.control.Button
        PresetedConfigurationsDropDown  matlab.ui.control.DropDown
        PresetedConfigurationsDropDownLabel  matlab.ui.control.Label
        SetMaxButton                    matlab.ui.control.Button
        SetMinButton                    matlab.ui.control.Button
        Set0Button                      matlab.ui.control.Button
        MovePanel                       matlab.ui.container.Panel
        DownButton                      matlab.ui.control.Button
        BigDownButton                   matlab.ui.control.Button
        BigUpButton                     matlab.ui.control.Button
        UpButton                        matlab.ui.control.Button
        ComandEditField                 matlab.ui.control.EditField
        MonitorTextArea                 matlab.ui.control.TextArea
    end


    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    
    properties (Access = private)
    ESP32           % El puerto serie
    TimerDatos      % El cronómetro para pedir datos
    PauseTime = 3   % Duración de la pausa de estabilización

    % Hueco para cargar nuestra ventana secundaria (configuracion)
    DialogoParametros
    
    % Registro de alturas del ciclo
    AlturaMax = 0
    AlturaMin = 0

    % Registro de estado de paneles
    estadoPrevioSet
    estadoPrevioMove
    estadoPrevioTest
    estadoPrevioParam

    % Registro del número de ciclos
    NumCiclos = 20

    %Perfiles de ensayo guardados
    TablaPerfiles

    end

    methods (Access = private)
        

        % Función que permite entender los mensajes enviados desde la ESP32
        function leerMensajeSerie(app, src, ~)
            try
                mensaje = readline(src);
                
                % 1. Confirmación de CERO
                if startsWith(mensaje, "ZERO POSITION SET")
                    app.Set0Button.Enable = 'off';          % Paso siguiente
                    app.SetMinButton.Enable = 'on';
                    app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> CERO set"];
        
                % 2. Recepción y Validación de MÍNIMO
                elseif startsWith(mensaje, "MIN:")
                    val = str2double(extractAfter(mensaje, "MIN:"));
                    
                    if val >= 0
                        app.AlturaMin = val;
                        app.SetMinButton.Enable = 'off';    %Paso siguiente
                        app.SetMaxButton.Enable = 'on';
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; 
                            "> MINIMUM set at: " + string(val)];
                    else
                        uialert(app.FlexBenchAppUIFigure, "MIN HEIGHT must be greater or equal than ZERO.", "Calibration error");
                    end
        
                % 3. Recepción y Validación de MÁXIMO
                elseif startsWith(mensaje, "MAX:")
                    val = str2double(extractAfter(mensaje, "MAX:"));
                    
                    if val > app.AlturaMin
                        app.AlturaMax = val;
                        app.SetMaxButton.Enable = 'off';
                        app.SetHeightsButton.Enable = 'on'; % Re-habilitamos por si se quiere recalibrar
                        set(app.TestPanel.Children, 'Enable', 'on');
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; 
                            "> MAXIMUM set at: " + string(val) ;"> Test Ready"];

                        % --- VENTANA EMERGENTE PARA GUARDAR PERFIL ---
                        prompt = {'Name for the new preset:', 'Number of Cycles:'};
                        dlgtitle = 'Save Preset';
                        dims = [1 50];
                        definput = {'New_Preset', num2str(app.NumCiclos)};
                        respuesta = inputdlg(prompt, dlgtitle, dims, definput);
                        
                        if ~isempty(respuesta) % Si el usuario no cancela
                            nuevoNombre = respuesta{1};
                            nuevosCiclos = str2double(respuesta{2});
                            
                            % Añadir a la tabla interna
                            nuevaFila = cell2table({nuevoNombre, app.AlturaMin, app.AlturaMax, nuevosCiclos}, ...
                                'VariableNames', {'Nombre_Perfil', 'Min', 'Max', 'Ciclos'});
                            app.TablaPerfiles = [app.TablaPerfiles; nuevaFila];
                            
                            % Guardar en el archivo Excel
                            try
                                rutaScript = fileparts(mfilename('fullpath'));
                                if isempty(rutaScript) || contains(rutaScript, 'Temp'), rutaScript = pwd; end
                                rutaExcel = fullfile(rutaScript, 'Test_profile.xlsx');
                                writetable(app.TablaPerfiles, rutaExcel);
                                
                                % Actualizar DropDown
                                app.PresetedConfigurationsDropDown.Items = app.TablaPerfiles.Nombre_Perfil;
                                app.PresetedConfigurationsDropDown.Value = nuevoNombre;
                                app.CycleNumberEditField.Value = nuevosCiclos;
                                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Preset saved perfectly."];
                            catch ME
                                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Error saving Excel: " + ME.message];
                                uialert(app.FlexBenchAppUIFigure, "Error saving preset to Excel: " + ME.message, "Excel Error", 'Icon', 'error');
                            end
                        end
                        
                        % --- RESTAURAR FASE 2 (VOLVER A LA NORMALIDAD) ---
                        % 1. Ocultamos los botones de calibración
                        app.SetMinButton.Visible = 'off';
                        app.SetMaxButton.Visible = 'off';
                        
                        % 2. Mostramos de nuevo el menú y el botón de Set Heights
                        app.PresetedConfigurationsDropDown.Visible = 'on';
                        app.PresetedConfigurationsDropDownLabel.Visible = 'on';
                        app.PresetedConfigurationsDropDownLabel.Visible = 'on';
                        app.SetHeightsButton.Visible = 'on';
                        
                        % 3. Habilitamos el panel de ensayo
                        set(app.TestPanel.Children, 'Enable', 'on');
                        app.StartTestButton.Enable = "on"; 
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Test Ready"];
                    else
                        uialert(app.FlexBenchAppUIFigure, "MAX HEIGHT must be greater than MIN HEIGHT.", "Calibration error");
                    end

                % 4. Resistencia
                elseif startsWith(mensaje, "RES")
                    % Extraemos el número de forma segura
                    numeros = regexp(mensaje, '-?\d+\.?\d*', 'match'); 
                    if ~isempty(numeros), resistencia = str2double(numeros{1}); end
                    app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> RES: " + string(resistencia) + " Ω"];
                end
                scroll(app.MonitorTextArea, 'bottom');
            catch
                %Si no puedo leer no hago nada
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.BaudRateDropDown.Value = '115200';
            % Deshabilitación inicial
            set(app.SetPanel.Children, 'Enable', 'off');
            set(app.MovePanel.Children, 'Enable', 'off');
            set(app.TestPanel.Children, 'Enable', 'off');
            set(app.ResistancePanel.Children, 'Enable', 'off');
            puertos = serialportlist();
            app.PortDropDown.Items = puertos;
            
            % Carga perfiles de ensayo
            try
                % 1. Localizar la carpeta exacta de la aplicación
                rutaScript = fileparts(which('FlexBenchApp.mlapp'));
    
                % Si por algún motivo no lo encuentra (ej. si compilas la app), usa pwd como último recurso
                if isempty(rutaScript)
                    rutaScript = pwd;
                end
    
                rutaExcel = fullfile(rutaScript, 'perfiles_ensayo.xlsx');
                
                % 2. Buscar el Excel en esa misma carpeta
                rutaExcel = fullfile(rutaScript, 'Test_profile.xlsx');
                
                % 3. Leer los datos y rellenar el menú
                app.TablaPerfiles = readtable(rutaExcel);
                app.PresetedConfigurationsDropDown.Items = app.TablaPerfiles.Nombre_Perfil;
                
            catch ME
                % Si no encuentra el archivo o está mal escrito
                app.PresetedConfigurationsDropDown.Items = {'Presets no encontrados'};
                app.PresetedConfigurationsDropDown.Enable = 'off';
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Warning: Profile excel couldn't be loaded."];
                uialert(app.FlexBenchAppUIFigure, "The profile presets file (Test_profile.xlsx) couldn't be loaded. Presets are disabled.", "File Error", 'Icon', 'warning');
            end
            
            % Precargar la ventana secundaria oculta
            app.DialogoParametros = SpecimenParamsDialog(); % Ojo: Usa el nombre exacto de tu archivo .mlapp
            app.DialogoParametros.UIFigure.Visible = 'off';
        end

        % Drop down opening function: PortDropDown
        function PortDropDownOpening(app, event)
            app.PortDropDown.Items = serialportlist();
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            try
                % Se lee lo seleccionado en los desplegables del Puerto y BaurRate
                app.ESP32 = serialport(app.PortDropDown.Value, str2double(app.BaudRateDropDown.Value));
                
                % Se configura el terminador a "Enter" (CR/LF)
                configureTerminator(app.ESP32, "CR/LF");

                % Se ejecuta leerMensajeSerie cada vez que se lea un terminator (CR/LF), 
                configureCallback(app.ESP32, "terminator", @app.leerMensajeSerie);
                
                % Cambiamos la luz a verde y el texto del botón
                app.ConnectLamp.Color = 'green';
                app.ConnectButton.Text = 'Connected';
                app.ConnectButton.Enable = 'off'; % Desactivamos el botón para no conectar 2 veces
                app.PortDropDown.Enable = "off";
                app.BaudRateDropDown.Enable = "off";

                % ESTADO 1: Liberamos control manual, Resistencia y Set 0
                set(app.MovePanel.Children, 'Enable', 'on');
                set(app.ResistancePanel.Children, 'Enable', 'on');
                
                set(app.SetPanel.Children, 'Enable', 'on');
                app.Set0Button.Enable = 'on';
                app.Set0Button.Visible = 'on'; % Lo mostramos
                
                % Ocultamos/Bloqueamos el resto del panel Set y Test
                app.PresetedConfigurationsDropDown.Visible = 'off';
                app.PresetedConfigurationsDropDownLabel.Visible = 'off';
                app.SetHeightsButton.Visible = 'off';
                app.SetMinButton.Visible = 'off';
                app.SetMaxButton.Visible = 'off';
                
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Phase 1: Move to start position and click Set0."];
                
            catch ME
                % Si algo falla, sacamos una alerta
                uialert(app.FlexBenchAppUIFigure, "Connection error: " + ME.message, "Connection Error");
                app.ConnectLamp.Color = 'red';
                app.ConnectButton.Text = 'Error in connection';
            end
        end

        % Value changed function: ComandEditField
        function ComandEditFieldValueChanged(app, event)
            % 1. Se lee el mensaje y se pone en mayúsculas
            textoEscrito = upper(app.ComandEditField.Value);
            
            % 2. Se verifica que el puerto este conectado
            if isempty(app.ESP32) || ~isvalid(app.ESP32)
                uialert(app.FlexBenchAppUIFigure, "Connect the port first.", "Error");
                return;
            end
            
            % 3. Se envia el mensaje a la ESP32
            writeline(app.ESP32, textoEscrito);
            
            % 4. Se muestra en la terminal el mensaje con "> "
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> " + textoEscrito];
            scroll(app.MonitorTextArea, 'bottom');
            
            % 5. Se limpia la barra de comandos
            app.ComandEditField.Value = '';
            
        end

        % Button pushed function: UpButton
        function UpButtonPushed(app, event)
            writeline(app.ESP32,"V50"); %Manda subir 5 steps
        end

        % Button pushed function: DownButton
        function DownButtonPushed(app, event)
            writeline(app.ESP32,"W50") %Manda bajar 5 steps
        end

        % Button pushed function: SetMaxButton
        function SetMaxButtonPushed(app, event)
            if ~isempty(app.ESP32) && isvalid(app.ESP32)
                writeline(app.ESP32, "P2"); % Pide posición máxima
            end
        end

        % Button pushed function: SetMinButton
        function SetMinButtonPushed(app, event)
            if ~isempty(app.ESP32) && isvalid(app.ESP32)
                writeline(app.ESP32, "P1"); % Pide posición mínima
            end
        end

        % Button pushed function: SetHeightsButton
        function SetHeightsButtonPushed(app, event)
            % Oculatamos las Preconfs y el boton
            app.PresetedConfigurationsDropDown.Visible = 'off';
            app.PresetedConfigurationsDropDownLabel.Visible = 'off';
            app.SetHeightsButton.Visible = 'off';
            
            % Mostramos los botones de calibración
            app.SetMinButton.Visible = 'on';
            app.SetMaxButton.Visible = 'on';
            
            app.SetMinButton.Enable = 'on';
            app.SetMaxButton.Enable = 'off';
            
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> CALIBRATION: Move to minimum bend and click SetMin."];
            scroll(app.MonitorTextArea, 'bottom');
        end

        % Button pushed function: Set0Button
        function Set0ButtonPushed(app, event)
            if ~isempty(app.ESP32) && isvalid(app.ESP32)
                writeline(app.ESP32, "S"); % Manda establecer la posición como nuevo cero

                %Cero Oculto
                app.Set0Button.Enable = 'off';
                app.Set0Button.Visible = 'off';
                
                % Mostrar Presets y Set Heigths
                app.PresetedConfigurationsDropDown.Visible = 'on';
                app.PresetedConfigurationsDropDownLabel.Visible = 'on';
                app.SetHeightsButton.Visible = 'on';
            end
        end

        % Button pushed function: BigUpButton
        function BigUpButtonPushed(app, event)
            writeline(app.ESP32,"V2000")  %Manda subir 50 steps
        end

        % Button pushed function: BigDownButton
        function BigDownButtonPushed(app, event)
            writeline(app.ESP32,"W2000")  %Manda bajar 50 steps
        end

        % Value changed function: StartTestButton
        function StartTestButtonValueChanged(app, event)
            
            % ==========================================
            % 0. LÓGICA DEL STATE BUTTON (START / STOP)
            % ==========================================
            if app.StartTestButton.Value == false
                app.StartTestButton.Text = 'Stopping...';
                app.StartTestButton.BackgroundColor = [0.96 0.96 0.96];
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Stopping test... Please wait..."];
                scroll(app.MonitorTextArea, 'bottom');
                drawnow;
                return; 
            end

            app.StartTestButton.Text = 'STOP';
            app.StartTestButton.BackgroundColor = [1 0.4 0.4]; 
            drawnow;

            % ============================= 
            % 1. COMPROBACIONES INICIALES
            % =============================
            function abortarInicio(mensaje, titulo)
                uialert(app.FlexBenchAppUIFigure, mensaje, titulo);
                app.StartTestButton.Value = false;
                app.StartTestButton.Text = 'Start Test'; 
                app.StartTestButton.BackgroundColor = [0.96 0.96 0.96];
                drawnow;
            end

            if isempty(app.ESP32) || ~isvalid(app.ESP32)
                abortarInicio("Please, connect first the port", "Connection error"); return;
            end
            
            if app.AlturaMax <= app.AlturaMin
                abortarInicio("Please calibrate the Minimum and Maximum heights or load a preset first.", "Calibration Missing"); 
                return;
            end
            
            % ==========================================
            % 2. ABRIR TU NUEVA VENTANA Y RECIBIR DATOS
            % ==========================================
            
            % ESCUDO 1: Si la ventana fue destruida (por la X roja) o no existe, la recreamos
            if isempty(app.DialogoParametros) || ~isvalid(app.DialogoParametros)
                app.DialogoParametros = SpecimenParamsDialog();
            end

            app.DialogoParametros.TabGroup.SelectedTab = app.DialogoParametros.TestTab;
            app.DialogoParametros.RepetitionsEditField.Value = app.NumCiclos;
            app.DialogoParametros.IsCanceled = true; 
            app.DialogoParametros.UIFigure.Visible = 'on';
            uiwait(app.DialogoParametros.UIFigure);
            
            % ESCUDO 2: Comprobamos que el objeto siga siendo válido ANTES de leer IsCanceled
            if ~isvalid(app.DialogoParametros) || app.DialogoParametros.IsCanceled
                abortarInicio("Test cancelled: Specimen parameters are required.", "Cancelled"); 
                return;
            end
            
            % Recoger todos los parámetros de tu nueva ventana
            specimenName = app.DialogoParametros.SpecimenName;
            totalTests   = app.DialogoParametros.TotalTests;
            L0_cm        = app.DialogoParametros.Length_cm;
            width_cm     = app.DialogoParametros.Width_cm;
            thickness_cm = app.DialogoParametros.Thickness_cm;
            infill_porc  = app.DialogoParametros.Infill;
            genExcel = app.DialogoParametros.GenerateExcel;
            nCiclos = app.DialogoParametros.Cycles;
            nFilter = app.DialogoParametros.FilterInterval;
            app.NumCiclos = nCiclos;

            % Variables para mantener compatibilidad con tu código del Excel que viene abajo
            strLength = num2str(L0_cm);
            strWidth = num2str(width_cm);
            
            % Validaciones de seguridad de los números
            if isnan(L0_cm) || L0_cm <= 0
                abortarInicio("Please, enter a valid numeric Length > 0.", "Error");
                return;
            end
            if isnan(width_cm) || width_cm <= 0
                abortarInicio("Please, enter a valid numeric Width > 0.", "Error");
                return;
            end
            if isnan(thickness_cm) || thickness_cm <= 0
                abortarInicio("Please, enter a valid numeric Thickness > 0.", "Error");
                return;
            end
            if ismissing(specimenName) || specimenName == ""
                abortarInicio("Please, enter a Specimen Name or Code.", "Error");
                return;
            end
            if isnan(totalTests) || totalTests < 1 || floor(totalTests) ~= totalTests
                abortarInicio("Please, enter a valid integer for Number of Consecutive Tests >= 1.", "Error");
                return;
            end
            if nCiclos <= 0 
                abortarInicio("The number of cycles must be greater than 0.", "Error");
                return;
            end
            
            % ==========================================
            % 3. EJECUCIÓN DEL ENSAYO (ESCUDO TRY-CATCH)
            % ==========================================
            try
                set(app.MovePanel.Children, 'Enable', 'off');
                set(app.SetPanel.Children, 'Enable', 'off');
                set(app.TestPanel.Children, 'Enable', 'on');
                set(app.ResistancePanel.Children, 'Enable', 'off');
    
                configureCallback(app.ESP32, "off");
                flush(app.ESP32); 
                
                % ==========================================
                % BUCLE EXTERNO BATCH
                % ==========================================
                for nTestActual = 1:totalTests
                    if app.StartTestButton.Value == false, break; end 
                    
                    app.MonitorTextArea.Value = [app.MonitorTextArea.Value; ...
                        "====================================="; ...
                        sprintf("> BATCH: Starting Test %d of %d", nTestActual, totalTests); ...
                        "> Preparing: Going to max height..."];
                    scroll(app.MonitorTextArea, 'bottom'); drawnow;
                    
                    writeline(app.ESP32, "P");
                    posActual = NaN;
                    while true
                        resp = readline(app.ESP32);
                        if startsWith(resp, "POS"), num = regexp(resp, '-?\d+\.?\d*', 'match');
                            posActual = str2double(num{1});
                            break;
                        end
                    end
                    
                    posicionPlana = (app.AlturaMax + app.AlturaMin) / 2;
                    amplitudMedia = (app.AlturaMax - app.AlturaMin) / 2;
                    distancia = posicionPlana - posActual;
                   
                    if distancia > 0, writeline(app.ESP32, "U" + string(distancia));
                    elseif distancia < 0, writeline(app.ESP32, "D" + string(-distancia)); end
                        
                    if distancia ~= 0
                        while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED")
                            drawnow;
                            if app.StartTestButton.Value == false, break; end 
                        end
                    end
                    
                    if app.StartTestButton.Value == false, break; end 
    
                    % 4. BUCLE DE ENSAYO
                    pasosMuestreo = 1; datosEnsayo = [];
                    t_inicio = tic;
                    posTemp = NaN; 
                    
                    for i = 1:nCiclos
                        if app.StartTestButton.Value == false, break; end 
                        
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; sprintf("> TEST %d: Cycle %d/%d (0.0%%)", nTestActual, i, nCiclos)];
                        scroll(app.MonitorTextArea, 'bottom');
                        drawnow;
    
                        pasosTotalesCiclo = amplitudMedia * 4; pasosDados = 0;
                        
                        % .2a SUBIDA 
                        pasosRestantes = amplitudMedia;
                        while pasosRestantes > 0
                            if app.StartTestButton.Value == false, break; end 
                            pasos = min(pasosMuestreo, pasosRestantes);
                            writeline(app.ESP32, "U" + string(pasos));
                            while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED"); drawnow; end
                            
                            writeline(app.ESP32, "P");
                            posTemp = NaN;
                            while true, resp = readline(app.ESP32);
                                if startsWith(resp, "POS:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    posTemp = str2double(num{1});
                                    break;
                                end
                            end
                            writeline(app.ESP32, "R");
                            resTemp = NaN;
                            while true, resp = readline(app.ESP32);
                                if startsWith(resp, "RES:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    resTemp = str2double(num{1});
                                    break;
                                end
                            end
    
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp, toc(t_inicio)];
                            pasosRestantes = pasosRestantes - pasos; pasosDados = pasosDados + pasos;
                            progreso = (pasosDados / pasosTotalesCiclo) * 100;
                            lineas = string(app.MonitorTextArea.Value);
                            lineas(end) = sprintf("> TEST %d: Cycle %d/%d (%.1f%%)", nTestActual, i, nCiclos, progreso);
                            app.MonitorTextArea.Value = cellstr(lineas);
                            drawnow; 
                        end
                        if app.StartTestButton.Value == false, break; end 
                        
                        % .2b Pausa en Máximo (CUENTA ATRÁS ENTERA)
                        lineas = string(app.MonitorTextArea.Value);
                        lineas(end) = sprintf("> TEST %d: Cycle %d/%d (25.0%%)", nTestActual, i, nCiclos);
                        lineas = [lineas; sprintf("  -> Stabilizing at Maximum (%ds)...", app.PauseTime)]; 
                        app.MonitorTextArea.Value = cellstr(lineas);
                        scroll(app.MonitorTextArea, 'bottom');
                        drawnow;
                        
                        t_pausa = tic;
                        segundoActual = app.PauseTime;
                        while toc(t_pausa) < app.PauseTime
                            if app.StartTestButton.Value == false, break; end 
                            writeline(app.ESP32, "R");
                            resTemp = NaN;
                            while true, resp = readline(app.ESP32);
                                if startsWith(resp, "RES:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    resTemp = str2double(num{1});
                                    break;
                                end
                            end
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp, toc(t_inicio)]; 
                            
                            segundoRestante = ceil(app.PauseTime - toc(t_pausa));
                            if segundoRestante < segundoActual && segundoRestante > 0
                                lineasUI = string(app.MonitorTextArea.Value);
                                lineasUI(end) = sprintf("  -> Stabilizing at Maximum (%ds)...", segundoRestante);
                                app.MonitorTextArea.Value = cellstr(lineasUI); drawnow;
                                segundoActual = segundoRestante;
                            end
                        end
                        if app.StartTestButton.Value == false, break; end 
                        lineas = string(app.MonitorTextArea.Value);
                        lineas(end) = [];
                        app.MonitorTextArea.Value = cellstr(lineas);
                        drawnow;
                        
                        % .2c BAJADA 
                        pasosRestantes = amplitudMedia*2;
                        while pasosRestantes > 0
                            if app.StartTestButton.Value == false, break; end 
                            pasos = min(pasosMuestreo, pasosRestantes);
                            writeline(app.ESP32, "D" + string(pasos));
                            while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED"); drawnow; end
                            
                            writeline(app.ESP32, "P");
                            posTemp = NaN;
                            while true, resp = readline(app.ESP32);
                                if startsWith(resp, "POS:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    posTemp = str2double(num{1});
                                    break;
                                end
                            end
                            writeline(app.ESP32, "R");
                            resTemp = NaN;
                            while true
                                resp = readline(app.ESP32);
                                if startsWith(resp, "RES:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    resTemp = str2double(num{1});
                                    break;
                                end
                            end
                            
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp, toc(t_inicio)];
                            pasosRestantes = pasosRestantes - pasos;
                            pasosDados = pasosDados + pasos;
                            progreso = (pasosDados / pasosTotalesCiclo) * 100;
                            lineas = string(app.MonitorTextArea.Value);
                            lineas(end) = sprintf("> TEST %d: Cycle %d/%d (%.1f%%)", nTestActual, i, nCiclos, progreso);
                            app.MonitorTextArea.Value = cellstr(lineas);
                            drawnow; 
                        end
                        if app.StartTestButton.Value == false, break; end 
    
                        % .2d Pausa en Mínimo (CUENTA ATRÁS ENTERA)
                        lineas = string(app.MonitorTextArea.Value); 
                        lineas = [lineas; sprintf("  -> Stabilizing at Minimum (%ds)...", app.PauseTime)]; 
                        app.MonitorTextArea.Value = cellstr(lineas);
                        scroll(app.MonitorTextArea, 'bottom');
                        drawnow;
                        
                        t_pausa = tic;
                        segundoActual = app.PauseTime;
                        while toc(t_pausa) < app.PauseTime
                            if app.StartTestButton.Value == false, break; end 
                            writeline(app.ESP32, "R");
                            resTemp = NaN;
                            while true, resp = readline(app.ESP32);
                                if startsWith(resp, "RES:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    resTemp = str2double(num{1});
                                    break;
                                end
                            end
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp, toc(t_inicio)]; 
                            
                            segundoRestante = ceil(app.PauseTime - toc(t_pausa));
                            if segundoRestante < segundoActual && segundoRestante > 0
                                lineasUI = string(app.MonitorTextArea.Value);
                                lineasUI(end) = sprintf("  -> Stabilizing at Minimum (%ds)...", segundoRestante);
                                app.MonitorTextArea.Value = cellstr(lineasUI);
                                drawnow;
                                segundoActual = segundoRestante;
                            end
                        end
                        if app.StartTestButton.Value == false, break; end 
                        lineas = string(app.MonitorTextArea.Value);
                        lineas(end) = [];
                        app.MonitorTextArea.Value = cellstr(lineas);
                        drawnow;
    
                        % .2e SUBIDA 
                        pasosRestantes = amplitudMedia; 
                        while pasosRestantes > 0
                            if app.StartTestButton.Value == false, break; end 
                            pasos = min(pasosMuestreo, pasosRestantes);
                            writeline(app.ESP32, "U" + string(pasos));
                            while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED"); drawnow; end
    
                            writeline(app.ESP32, "P"); posTemp = NaN;
                            while true
                                resp = readline(app.ESP32);
                                if startsWith(resp, "POS:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    posTemp = str2double(num{1});
                                    break;
                                end
                            end
                            writeline(app.ESP32, "R"); resTemp = NaN;
                            while true
                                resp = readline(app.ESP32);
                                if startsWith(resp, "RES:"),
                                    num = regexp(resp, '-?\d+\.?\d*', 'match');
                                    resTemp = str2double(num{1});
                                    break; 
                                end
                            end
    
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp, toc(t_inicio)];
                            pasosRestantes = pasosRestantes - pasos;
                            pasosDados = pasosDados + pasos;
                            progreso = (pasosDados / pasosTotalesCiclo) * 100;
                            lineas = string(app.MonitorTextArea.Value);
                            lineas(end) = sprintf("> TEST %d: Cycle %d/%d (%.1f%%)", nTestActual, i, nCiclos, progreso);
                            app.MonitorTextArea.Value = cellstr(lineas);
                            drawnow;
                        end
                        if app.StartTestButton.Value == false, break; end 
    
                        % .2f Pausa en Medio (CUENTA ATRÁS ENTERA)
                        lineas = string(app.MonitorTextArea.Value); 
                        lineas = [lineas; sprintf("  -> Stabilizing at Flat Position (%ds)...", app.PauseTime)]; 
                        app.MonitorTextArea.Value = cellstr(lineas);
                        scroll(app.MonitorTextArea, 'bottom');
                        drawnow;
                        
                        t_pausa = tic;
                        segundoActual = app.PauseTime;
                        while toc(t_pausa) < app.PauseTime
                            if app.StartTestButton.Value == false, break; end 
                            writeline(app.ESP32, "R");
                            resTemp = NaN;
                            while true
                                resp = readline(app.ESP32);
                                if startsWith(resp, "RES:")
                                    num = regexp(resp, '-?\d+\.?\d*', 'match'); 
                                    resTemp = str2double(num{1});
                                    break;
                                end
                            end
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp, toc(t_inicio)]; 
                            
                            segundoRestante = ceil(app.PauseTime - toc(t_pausa));
                            if segundoRestante < segundoActual && segundoRestante > 0
                                lineasUI = string(app.MonitorTextArea.Value);
                                lineasUI(end) = sprintf("  -> Stabilizing at Flat Position (%ds)...", segundoRestante);
                                app.MonitorTextArea.Value = cellstr(lineasUI); drawnow;
                                segundoActual = segundoRestante;
                            end
                        end
                        if app.StartTestButton.Value == false, break; end 
                        lineas = string(app.MonitorTextArea.Value); lineas(end) = []; 
                        lineas(end) = sprintf("> TEST %d: Cycle %d/%d (100.0%%) - Completed", nTestActual, i, nCiclos);
                        app.MonitorTextArea.Value = cellstr(lineas); drawnow;
                    end
    
                    % =======================
                    % 5. ENSAYO FIN Y EXCEL
                    % =======================
                    if app.StartTestButton.Value == false
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> TEST CANCELLED. Processing partial data..."];
                    else
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; sprintf("> TEST %d COMPLETED. Generating Excel...", nTestActual)];
                    end
                    scroll(app.MonitorTextArea, 'bottom');
                    drawnow; 
                    
                    if isempty(datosEnsayo)
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> No data collected. Excel skipped."];
                    else
                        resistenciaMedia = movmean(datosEnsayo(:, 3), nFilter);
                        datosCompletos = [datosEnsayo, resistenciaMedia]; 
                        
                        modulo = 1;
                        dientes = 60;
                        diametroPrimitivo = modulo * dientes;
                        avancePorVuelta = pi * diametroPrimitivo; 
                        pasosPorVueltaMotor = 200;
                        microstepping = 256;
                        avancePorPaso = avancePorVuelta / (pasosPorVueltaMotor * microstepping); 
                        
                        thickness_mm = thickness_cm * 10;
                        L0_mm = L0_cm * 10;
                        
                        columnaDeformacion = zeros(size(datosCompletos, 1), 1);
                        columnaGF = zeros(size(datosCompletos, 1), 1);
                        
                        ciclosEjecutados = max(datosCompletos(:, 1)); 
                        
                        for j = 1:ciclosEjecutados
                            idxCiclo = find(datosCompletos(:, 1) == j);
                            if ~isempty(idxCiclo)
                                R0 = datosCompletos(idxCiclo(1), 5);
                                Pos0 = datosCompletos(idxCiclo(1), 2); 
                                for k = 1:length(idxCiclo)
                                    fila = idxCiclo(k);
                                    deflexion_mm = abs(datosCompletos(fila, 2) - Pos0) * avancePorPaso; 
                                    epsilon = (6 * deflexion_mm * thickness_mm) / (L0_mm^2);
                                    columnaDeformacion(fila) = epsilon;
                                    deltaR = datosCompletos(fila, 5) - R0;
                                    variacionRelativaR = deltaR / R0;
                                    if abs(epsilon) < 1e-4, columnaGF(fila) = NaN; else, columnaGF(fila) = variacionRelativaR / epsilon; end
                                end
                            end
                        end
                        
                        datosCompletos = [datosCompletos, columnaDeformacion, columnaGF];
                        tablaDatos = array2table(datosCompletos, 'VariableNames', {'Cycle', 'Position', 'Resistance', 'Time', 'Average_Resistance', 'Strain', 'Gauge_Factor'});
                         
                        infoTest = sprintf("(Test %d of %d)", nTestActual, totalTests);
                        Attributes = {'Specimen Name'; 'Infill'; 'Length'; 'Thickness (mm)'; 'Width (cm)'; 'Test Number'};
                        Values = {specimenName; string(infill_porc); strLength + " cm"; string(thickness_mm); strWidth; infoTest};
                        tablaInfo = table(Attributes, Values, 'VariableNames', {'Attribute', 'Value'});
                        
                        if genExcel == true
                            rutaBase = pwd; 
                            rutaDestino = fullfile(rutaBase, 'Datos');
                            
                            if ~exist(rutaDestino, 'dir')
                                mkdir(rutaDestino);
                            end
                            
                            fechaStr = char(datetime('now', 'Format', 'yy-MM-dd     HH;mm;ss'));
                            nombreArchivo = fullfile(rutaDestino, sprintf("Test_%s_T%d_%s.xlsx", specimenName, nTestActual, fechaStr));
                            
                            writetable(tablaDatos, nombreArchivo, 'Sheet', 'Test_Data');
                            writetable(tablaInfo, nombreArchivo, 'Sheet', 'Specimen_Info');
                            
                            try
                                Excel = actxserver('Excel.Application');
                                Workbook = Excel.Workbooks.Open(nombreArchivo);
                                                 
                                % Autoajustar la hoja de datos
                                Sheet = Workbook.Sheets.Item('Test_Data'); 
                                Sheet.Columns.AutoFit();
                                SheetInfo = Workbook.Sheets.Item('Specimen_Info');
                                SheetInfo.Columns.AutoFit();

                                numFilas = size(datosCompletos, 1) + 1; 
                                
                                maxTiempo = max(datosCompletos(:, 4));
                                escalaMaxTiempo = maxTiempo * 1.05;
                                minRes = min(datosCompletos(:, 5));
                                maxRes = max(datosCompletos(:, 5));
                                margenRes = (maxRes - minRes) * 0.1;
                                if margenRes == 0, margenRes = 50; end
                                escalaMinRes = floor((minRes - margenRes) / 10) * 10;
                                escalaMaxRes = ceil((maxRes + margenRes) / 10) * 10;
                                
                                % Gráfico 1
                                Grafico1 = Excel.Charts.Add; Grafico1.ChartType = 'xlXYScatter'; 
                                while Grafico1.SeriesCollection.Count > 0, Grafico1.SeriesCollection.Item(1).Delete; end
                                
                                %Serie 1
                                Serie1 = Grafico1.SeriesCollection.NewSeries;
                                Serie1.XValues = Sheet.Range(sprintf('D2:D%d', numFilas));
                                Serie1.Values = Sheet.Range(sprintf('E2:E%d', numFilas));
                                Serie1.MarkerStyle = 8;
                                Serie1.MarkerSize = 2;
                                %Gráfico
                                Grafico1.HasTitle = true; Grafico1.ChartTitle.Text = 'Resistance vs Time (Filtered)';
                                Grafico1.HasLegend = false; 
                                Grafico1.Axes(1).HasTitle = true; Grafico1.Axes(1).AxisTitle.Text = 'Time (s)';
                                Grafico1.Axes(1).MinimumScale = 0; Grafico1.Axes(1).MaximumScale = escalaMaxTiempo;
                                Grafico1.Axes(2).HasTitle = true; Grafico1.Axes(2).AxisTitle.Text = 'Average Resistance (Ohms)';
                                Grafico1.Axes(2).MinimumScale = escalaMinRes; Grafico1.Axes(2).MaximumScale = escalaMaxRes;
                                Grafico1.Location(2, Sheet.Name); Shape1 = Sheet.Shapes.Item(Sheet.Shapes.Count);
                                Shape1.Width = 600; Shape1.Height = 350; Shape1.Top = 20; Shape1.Left = 550; 
                                
                                % Gráfico 2
                                Grafico2 = Excel.Charts.Add; Grafico2.ChartType = 'xlXYScatterLinesNoMarkers'; 
                                while Grafico2.SeriesCollection.Count > 0, Grafico2.SeriesCollection.Item(1).Delete; end
                                for c = 1:ciclosEjecutados
                                    filasCiclo = find(datosCompletos(:, 1) == c);
                                    if ~isempty(filasCiclo)
                                        Serie2 = Grafico2.SeriesCollection.NewSeries; Serie2.XValues = Sheet.Range(sprintf('E%d:E%d', filasCiclo(1) + 1, filasCiclo(end) + 1));
                                        Serie2.Values = Sheet.Range(sprintf('B%d:B%d', filasCiclo(1) + 1, filasCiclo(end) + 1)); Serie2.Name = sprintf('Cycle %d', c); Serie2.Format.Line.Weight = 1.0;
                                    end
                                end
                                Grafico2.HasTitle = true; Grafico2.ChartTitle.Text = 'Hysteresis: Position vs Resistance'; Grafico2.HasLegend = true; 
                                Grafico2.Axes(1).HasTitle = true; Grafico2.Axes(1).AxisTitle.Text = 'Average Resistance (Ohms)'; Grafico2.Axes(1).MinimumScale = escalaMinRes; Grafico2.Axes(1).MaximumScale = escalaMaxRes;
                                Grafico2.Axes(2).HasTitle = true; Grafico2.Axes(2).AxisTitle.Text = 'Position (Steps)';
                                Grafico2.Location(2, Sheet.Name); Shape2 = Sheet.Shapes.Item(Sheet.Shapes.Count);
                                Shape2.Width = 600; Shape2.Height = 350; Shape2.Top = Shape1.Top + Shape1.Height + 20; Shape2.Left = 550;
                                
                                % Gráfico 3
                                Grafico3 = Excel.Charts.Add; Grafico3.ChartType = 'xlXYScatter'; 
                                while Grafico3.SeriesCollection.Count > 0, Grafico3.SeriesCollection.Item(1).Delete; end
                                for c = 1:ciclosEjecutados
                                    filasCiclo = find(datosCompletos(:, 1) == c);
                                    if ~isempty(filasCiclo)
                                        Serie3 = Grafico3.SeriesCollection.NewSeries; Serie3.XValues = Sheet.Range(sprintf('D%d:D%d', filasCiclo(1) + 1, filasCiclo(end) + 1));
                                        Serie3.Values = Sheet.Range(sprintf('G%d:G%d', filasCiclo(1) + 1, filasCiclo(end) + 1)); Serie3.Name = sprintf('Cycle %d', c); Serie3.MarkerStyle = 8; Serie3.MarkerSize = 3;  
                                    end
                                end
                                Grafico3.HasTitle = true; Grafico3.ChartTitle.Text = 'Sensitivity: Gauge Factor vs Time'; Grafico3.HasLegend = true; 
                                Grafico3.Axes(1).HasTitle = true; Grafico3.Axes(1).AxisTitle.Text = 'Time (s)'; Grafico3.Axes(1).MinimumScale = 0; Grafico3.Axes(1).MaximumScale = escalaMaxTiempo;
                                Grafico3.Axes(2).HasTitle = true; Grafico3.Axes(2).AxisTitle.Text = 'Gauge Factor (GF)';
                                Grafico3.Location(2, Sheet.Name); Shape3 = Sheet.Shapes.Item(Sheet.Shapes.Count);
                                Shape3.Width = 600; Shape3.Height = 350; Shape3.Top = Shape2.Top + Shape2.Height + 20; Shape3.Left = 550;
                                
                                Workbook.Save; Workbook.Close; Excel.Quit; delete(Excel);
                                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Correctly saved: " + nombreArchivo];
                                scroll(app.MonitorTextArea, 'bottom');
                            catch ME
                                if exist('Excel', 'var') && isvalid(Excel), Excel.Quit; delete(Excel); end
                                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Warning: Native charting failed. " + ME.message];
                                uialert(app.FlexBenchAppUIFigure, "Excel charting or saving failed: " + ME.message, "Excel Warning", 'Icon', 'warning');
                            end
                        else
                            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Test completed. (Excel saving disabled)"];
                        end
                    end
                    
                    % ==========================================
                    % 6. PAUSA DE 5 MINUTOS ENTRE TESTS
                    % ==========================================
                    if nTestActual < totalTests && app.StartTestButton.Value == true
                        tiempoEspera = 300; 
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; ...
                            "> BATCH: Waiting 5 minutes for the next test to stabilize..."];
                        scroll(app.MonitorTextArea, 'bottom'); drawnow;
                        
                        t_espera = tic;
                        ultimoAviso = 0;
                        
                        while toc(t_espera) < tiempoEspera
                            if app.StartTestButton.Value == false
                                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> BATCH CANCELLED during wait time."];
                                scroll(app.MonitorTextArea, 'bottom'); drawnow;
                                break; 
                            end
                            
                            segundosPasados = floor(toc(t_espera));
                            
                            if segundosPasados > ultimoAviso && mod(segundosPasados, 60) == 0
                                minutosRestantes = (tiempoEspera - segundosPasados) / 60;
                                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; ...
                                    sprintf("  ... %d minute(s) remaining", minutosRestantes)];
                                scroll(app.MonitorTextArea, 'bottom');
                                ultimoAviso = segundosPasados;
                            end
                            drawnow;
                        end
                    end
                    
                end 
                
            catch ME
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> CRITICAL ERROR: " + ME.message];
                scroll(app.MonitorTextArea, 'bottom');
                uialert(app.FlexBenchAppUIFigure, "A critical error stopped the test: " + ME.message, "Critical Error", 'Icon', 'error');
            end
            
            % --- RESTAURAR LA NORMALIDAD ---
            app.StartTestButton.Value = false; 
            app.StartTestButton.Text = 'Start Test';
            app.StartTestButton.BackgroundColor = [0.96 0.96 0.96];
            
            set(app.MovePanel.Children, 'Enable', 'on');
            set(app.SetPanel.Children, 'Enable', 'on');
            set(app.TestPanel.Children, 'Enable', 'on');
            set(app.ResistancePanel.Children, 'Enable', 'on');
    
            configureCallback(app.ESP32, "terminator", @app.leerMensajeSerie);
            drawnow;
        end

        % Value changed function: ResistanceTestButton
        function ResistanceTestButtonValueChanged(app, event)
            
            % 0. Verificar conexión
            if isempty(app.ESP32) || ~isvalid(app.ESP32)
                app.ResistanceTestButton.Value = false;
                uialert(app.FlexBenchAppUIFigure, "Connect first the port.", "Warning");
                return;
            end
            
            % ==========================================
            % LÓGICA DE PARADA (STOP)
            % ==========================================
            if app.ResistanceTestButton.Value == false
                app.ResistanceTestButton.Text = 'Stopping...';
                app.ResistanceTestButton.BackgroundColor = [0.96 0.96 0.96];
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Stopping continuous reading..."];
                scroll(app.MonitorTextArea, 'bottom');
                drawnow;
                return;
            end
        
            % ==========================================
            % LÓGICA DE INICIO (START) Y DIÁLOGO
            % ==========================================
            
            % Mostrar la ventana pre-cargada y esperar a la acción del usuario
            app.DialogoParametros.IsCanceled = true; 
            app.DialogoParametros.UIFigure.Visible = 'on';
            app.DialogoParametros.TabGroup.SelectedTab = app.DialogoParametros.ResistanceTab;
        
            uiwait(app.DialogoParametros.UIFigure);
            
            % Si el usuario cancela o cierra la ventana con la cruz
            if app.DialogoParametros.IsCanceled
                app.ResistanceTestButton.Value = false;
                app.ResistanceTestButton.Text = 'Resistance Test';
                app.ResistanceTestButton.BackgroundColor = [0.96 0.96 0.96];
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Resistance test cancelled."];
                scroll(app.MonitorTextArea, 'bottom'); drawnow;
                return;
            end
            
            % Extraemos los datos de la app secundaria
            specimenName = app.DialogoParametros.SpecimenName;
            L0_cm        = app.DialogoParametros.Length_cm;
            width_cm     = app.DialogoParametros.Width_cm;
            thickness_cm = app.DialogoParametros.Thickness_cm;
            infill_porc  = app.DialogoParametros.Infill;
            genExcel     = app.DialogoParametros.GenerateExcel;
            intervalo    = app.DialogoParametros.FilterInterval;
        
            % Convertir las dimensiones a string para mantener la compatibilidad con el código del Excel
            strLength = num2str(L0_cm);
            strWidth  = num2str(width_cm);
        
            % Cambios visuales en el botón para indicar que está en ejecución
            app.ResistanceTestButton.Text = 'STOP';
            app.ResistanceTestButton.BackgroundColor = [1 0.4 0.4]; 
            
            % 1. BLOQUEAMOS PANELES SECUNDARIOS
            set(app.MovePanel.Children, 'Enable', 'off');
            set(app.SetPanel.Children, 'Enable', 'off');
            set(app.TestPanel.Children, 'Enable', 'off');
            
            % 2. APAGAMOS CALLBACK PARA LEER MANUALMENTE
            configureCallback(app.ESP32, "off");
            flush(app.ESP32);
            
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Starting Continuous Resistance Test..."];
            scroll(app.MonitorTextArea, 'bottom'); drawnow;
            
            datosResistencia = [];
            t_inicio = tic;
            ultimoRefrescoUI = tic;
            
            try
                % 3. BUCLE PRINCIPAL DE LECTURA
                while app.ResistanceTestButton.Value == true
                    writeline(app.ESP32, "R");
                    resTemp = NaN;
                    
                    % Esperar respuesta
                    while true
                        if app.ResistanceTestButton.Value == false, break; end 
                        resp = readline(app.ESP32);
                        if startsWith(resp, "RES:")
                            num = regexp(resp, '-?\d+\.?\d*', 'match'); 
                            if ~isempty(num)
                                resTemp = str2double(num{1}); 
                            end
                            break; 
                        end
                    end
                    
                    % Si cortamos o falla la lectura, salimos
                    if app.ResistanceTestButton.Value == false, break; end
                    if isnan(resTemp), continue; end 
                    
                    % Registrar dato
                    tiempoActual = toc(t_inicio);
                    datosResistencia = [datosResistencia; tiempoActual, resTemp];
                    
                    % Refresco UI anti-saturación
                    if toc(ultimoRefrescoUI) >= 1.0
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; ...
                            sprintf("> RES: %.2f Ω | Time: %.1f s", resTemp, tiempoActual)];
                        scroll(app.MonitorTextArea, 'bottom');
                        ultimoRefrescoUI = tic;
                    end
                    drawnow;
                end
                
                % ==========================================
                % 4. GENERACIÓN DEL EXCEL 
                % ==========================================
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Resistance test completed."];
                scroll(app.MonitorTextArea, 'bottom'); drawnow;
                
                if genExcel == true
                    if isempty(datosResistencia)
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> No data collected. Excel skipped."];
                    else
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Generating Excel..."];
                        drawnow;
                        
                        % Filtrado
                        resistenciaMedia = movmean(datosResistencia(:, 2), intervalo);
                        datosCompletos = [datosResistencia, resistenciaMedia];
                        
                        % Tabla de datos
                        tablaDatos = array2table(datosCompletos, 'VariableNames', {'Time_s', 'Resistance_Ohms', 'Filtered_Resistance_Ohms'});
                        
                        % Tabla de Info Probeta
                       thickness_mm = thickness_cm * 10;
                        Attributes = {'Specimen Name'; 'Infill'; 'Length'; 'Thickness (mm)'; 'Width (cm)'}; 
                        Values = {specimenName; string(infill_porc); strLength + " cm"; string(thickness_mm); strWidth};
                        tablaInfo = table(Attributes, Values, 'VariableNames', {'Attribute', 'Value'});
                                                
                        % Rutas relativas y carpeta Resistance
                        rutaBase = pwd;
                        rutaDestino = fullfile(rutaBase, 'Datos', 'Resistance');
                        if ~exist(rutaDestino, 'dir')
                            mkdir(rutaDestino); 
                        end
                        
                        fechaStr = char(datetime('now', 'Format', 'yy-MM-dd     HH;mm;ss'));
                        % Nombre incluye la probeta
                        nombreArchivo = fullfile(rutaDestino, sprintf("ResTest_%s_%s.xlsx", specimenName, fechaStr)); 
                        
                        % Escritura de ambas hojas
                        writetable(tablaDatos, nombreArchivo, 'Sheet', 'Resistance_Data');
                        writetable(tablaInfo, nombreArchivo, 'Sheet', 'Specimen_Info');
                        
                        % Automatización del Gráfico
                        try
                            Excel = actxserver('Excel.Application'); 
                            Workbook = Excel.Workbooks.Open(nombreArchivo);

                            
                            % Autoajustar la hoja de datos
                            Sheet = Workbook.Sheets.Item('Resistance_Data'); 
                            Sheet.Columns.AutoFit();
                            SheetInfo = Workbook.Sheets.Item('Specimen_Info');
                            SheetInfo.Columns.AutoFit();


                            numFilas = size(datosCompletos, 1) + 1; 
                            maxTiempo = max(datosCompletos(:, 1));
                            
                            Grafico1 = Excel.Charts.Add; 
                            Grafico1.ChartType = 'xlXYScatter'; 
                            while Grafico1.SeriesCollection.Count > 0, Grafico1.SeriesCollection.Item(1).Delete; end
                            
                            % Serie 1: Raw
                            Serie1 = Grafico1.SeriesCollection.NewSeries; 
                            Serie1.XValues = Sheet.Range(sprintf('A2:A%d', numFilas));
                            Serie1.Values = Sheet.Range(sprintf('B2:B%d', numFilas)); 
                            Serie1.Name = 'Raw Resistance';
                            Serie1.MarkerStyle = 8; Serie1.MarkerSize = 2;  
                            
                            % Serie 2: Filtrado
                            Serie2 = Grafico1.SeriesCollection.NewSeries; 
                            Serie2.XValues = Sheet.Range(sprintf('A2:A%d', numFilas));
                            Serie2.Values = Sheet.Range(sprintf('C2:C%d', numFilas)); 
                            Serie2.Name = 'Filtered Resistance';
                            Serie2.ChartType = 'xlXYScatterLinesNoMarkers'; 
                            Serie2.Format.Line.Weight = 2.0;
                            
                            Grafico1.HasTitle = true; Grafico1.ChartTitle.Text = 'Static Resistance vs Time'; 
                            Grafico1.HasLegend = true; 
                            Grafico1.Axes(1).HasTitle = true; Grafico1.Axes(1).AxisTitle.Text = 'Time (s)'; 
                            Grafico1.Axes(1).MinimumScale = 0; Grafico1.Axes(1).MaximumScale = maxTiempo * 1.05;
                            Grafico1.Axes(2).HasTitle = true; Grafico1.Axes(2).AxisTitle.Text = 'Resistance (Ohms)'; 
                            Grafico1.Location(2, Sheet.Name); 
                            
                            Shape1 = Sheet.Shapes.Item(Sheet.Shapes.Count);
                            Shape1.Width = 600; Shape1.Height = 350; Shape1.Top = 20; Shape1.Left = 300; 
                            
                            Workbook.Save; Workbook.Close; Excel.Quit; delete(Excel);
                            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Excel correctly saved: " + nombreArchivo];
                        catch ME
                            if exist('Excel', 'var') && isvalid(Excel), Excel.Quit; delete(Excel); end
                            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Warning: Native charting failed. " + ME.message];
                            uialert(app.FlexBenchAppUIFigure, "Excel charting or saving failed: " + ME.message, "Excel Warning", 'Icon', 'warning');
                        end
                    end
                else
                    app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Test completed. (Excel saving disabled)"];
                end
                
            catch ME
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> CRITICAL ERROR: " + ME.message];
                uialert(app.FlexBenchAppUIFigure, "A critical error stopped the resistance test: " + ME.message, "Critical Error", 'Icon', 'error');
            end
            
            % 5. RESTAURAMOS LA NORMALIDAD
            set(app.MovePanel.Children, 'Enable', 'on');
            set(app.SetPanel.Children, 'Enable', 'on');
            set(app.TestPanel.Children, 'Enable', 'on');
            
            app.ResistanceTestButton.Value = false;
            app.ResistanceTestButton.Text = 'Resistance Test';
            app.ResistanceTestButton.BackgroundColor = [0.96 0.96 0.96]; 
            
            configureCallback(app.ESP32, "terminator", @app.leerMensajeSerie);
            scroll(app.MonitorTextArea, 'bottom');
            drawnow;
        end

        % Value changed function: PresetedConfigurationsDropDown
        function PresetedConfigurationsDropDownValueChanged(app, event)
            nombrePerfil = string(app.PresetedConfigurationsDropDown.Value);
            
            % Buscamos la fila correspondiente en la tabla
            idx = find(app.TablaPerfiles.Nombre_Perfil == nombrePerfil);
            if isempty(idx), return; end
            
            % Extraemos los datos directamente en pasos
            app.AlturaMin = app.TablaPerfiles.Min(idx);
            app.AlturaMax = app.TablaPerfiles.Max(idx);
            ciclos    = app.TablaPerfiles.Ciclos(idx);
            
            % Actualizamos la interfaz
            app.NumCiclos = ciclos;
            set(app.TestPanel.Children, 'Enable', 'on');    % Habilitamos el panel para poder arrancar
            
            % Mensaje de consola
            msg = sprintf("> PRESET LOADED: %s | Min: %d steps, Max: %d steps, Cycles: %d", ...
                          nombrePerfil, app.AlturaMin, app.AlturaMax, ciclos);
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; msg];
            scroll(app.MonitorTextArea, 'bottom');
        end

        % Button down function: FlexBenchAppUIFigure
        function FlexBenchAppUIFigureButtonDown(app, event)
            if isvalid(app.DialogoParametros)
                delete(app.DialogoParametros); 
            end
            delete(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create FlexBenchAppUIFigure and hide until all components are created
            app.FlexBenchAppUIFigure = uifigure('Visible', 'off');
            app.FlexBenchAppUIFigure.Color = [0.9608 0.9608 0.9608];
            app.FlexBenchAppUIFigure.Position = [0 0 1540 845];
            app.FlexBenchAppUIFigure.Name = 'FlexBench App';
            app.FlexBenchAppUIFigure.ButtonDownFcn = createCallbackFcn(app, @FlexBenchAppUIFigureButtonDown, true);
            app.FlexBenchAppUIFigure.WindowState = 'maximized';

            % Create MonitorTextArea
            app.MonitorTextArea = uitextarea(app.FlexBenchAppUIFigure);
            app.MonitorTextArea.Editable = 'off';
            app.MonitorTextArea.FontName = 'Consolas';
            app.MonitorTextArea.FontSize = 16;
            app.MonitorTextArea.FontColor = [0 1 0];
            app.MonitorTextArea.BackgroundColor = [0 0 0];
            app.MonitorTextArea.Position = [20 60 700 750];
            app.MonitorTextArea.Value = {'CONSOLE:'};

            % Create ComandEditField
            app.ComandEditField = uieditfield(app.FlexBenchAppUIFigure, 'text');
            app.ComandEditField.ValueChangedFcn = createCallbackFcn(app, @ComandEditFieldValueChanged, true);
            app.ComandEditField.BackgroundColor = [0.8 0.8 0.8];
            app.ComandEditField.Position = [20 20 700 30];

            % Create MovePanel
            app.MovePanel = uipanel(app.FlexBenchAppUIFigure);
            app.MovePanel.BorderType = 'none';
            app.MovePanel.Position = [1250 50 200 200];

            % Create UpButton
            app.UpButton = uibutton(app.MovePanel, 'push');
            app.UpButton.ButtonPushedFcn = createCallbackFcn(app, @UpButtonPushed, true);
            app.UpButton.FontSize = 24;
            app.UpButton.Position = [16 109 76 76];
            app.UpButton.Text = '↑';

            % Create BigUpButton
            app.BigUpButton = uibutton(app.MovePanel, 'push');
            app.BigUpButton.ButtonPushedFcn = createCallbackFcn(app, @BigUpButtonPushed, true);
            app.BigUpButton.FontSize = 24;
            app.BigUpButton.Position = [108 109 76 76];
            app.BigUpButton.Text = '⇑';

            % Create BigDownButton
            app.BigDownButton = uibutton(app.MovePanel, 'push');
            app.BigDownButton.ButtonPushedFcn = createCallbackFcn(app, @BigDownButtonPushed, true);
            app.BigDownButton.FontSize = 24;
            app.BigDownButton.Position = [108 17 76 76];
            app.BigDownButton.Text = '⇓';

            % Create DownButton
            app.DownButton = uibutton(app.MovePanel, 'push');
            app.DownButton.ButtonPushedFcn = createCallbackFcn(app, @DownButtonPushed, true);
            app.DownButton.FontSize = 24;
            app.DownButton.Position = [16 17 76 76];
            app.DownButton.Text = '↓';

            % Create SetPanel
            app.SetPanel = uipanel(app.FlexBenchAppUIFigure);
            app.SetPanel.BorderType = 'none';
            app.SetPanel.Position = [1200 280 300 200];

            % Create Set0Button
            app.Set0Button = uibutton(app.SetPanel, 'push');
            app.Set0Button.ButtonPushedFcn = createCallbackFcn(app, @Set0ButtonPushed, true);
            app.Set0Button.FontSize = 18;
            app.Set0Button.Enable = 'off';
            app.Set0Button.Visible = 'off';
            app.Set0Button.Position = [50 100 200 80];
            app.Set0Button.Text = 'Set0';

            % Create SetMinButton
            app.SetMinButton = uibutton(app.SetPanel, 'push');
            app.SetMinButton.ButtonPushedFcn = createCallbackFcn(app, @SetMinButtonPushed, true);
            app.SetMinButton.FontSize = 18;
            app.SetMinButton.Enable = 'off';
            app.SetMinButton.Visible = 'off';
            app.SetMinButton.Position = [30 100 100 80];
            app.SetMinButton.Text = 'SetMin';

            % Create SetMaxButton
            app.SetMaxButton = uibutton(app.SetPanel, 'push');
            app.SetMaxButton.ButtonPushedFcn = createCallbackFcn(app, @SetMaxButtonPushed, true);
            app.SetMaxButton.FontSize = 18;
            app.SetMaxButton.Enable = 'off';
            app.SetMaxButton.Visible = 'off';
            app.SetMaxButton.Position = [170 100 100 80];
            app.SetMaxButton.Text = 'SetMax';

            % Create PresetedConfigurationsDropDownLabel
            app.PresetedConfigurationsDropDownLabel = uilabel(app.SetPanel);
            app.PresetedConfigurationsDropDownLabel.HorizontalAlignment = 'center';
            app.PresetedConfigurationsDropDownLabel.Position = [75 50 150 25];
            app.PresetedConfigurationsDropDownLabel.Text = 'Preseted Configurations';

            % Create PresetedConfigurationsDropDown
            app.PresetedConfigurationsDropDown = uidropdown(app.SetPanel);
            app.PresetedConfigurationsDropDown.Items = {'Select profile'};
            app.PresetedConfigurationsDropDown.ValueChangedFcn = createCallbackFcn(app, @PresetedConfigurationsDropDownValueChanged, true);
            app.PresetedConfigurationsDropDown.FontSize = 14;
            app.PresetedConfigurationsDropDown.Position = [15 17 270 25];
            app.PresetedConfigurationsDropDown.Value = 'Select profile';

            % Create SetHeightsButton
            app.SetHeightsButton = uibutton(app.SetPanel, 'push');
            app.SetHeightsButton.ButtonPushedFcn = createCallbackFcn(app, @SetHeightsButtonPushed, true);
            app.SetHeightsButton.FontSize = 18;
            app.SetHeightsButton.Position = [50 100 200 80];
            app.SetHeightsButton.Text = 'Set Heights';

            % Create TestPanel
            app.TestPanel = uipanel(app.FlexBenchAppUIFigure);
            app.TestPanel.BorderType = 'none';
            app.TestPanel.Position = [850 280 300 200];

            % Create StartTestButton
            app.StartTestButton = uibutton(app.TestPanel, 'state');
            app.StartTestButton.ValueChangedFcn = createCallbackFcn(app, @StartTestButtonValueChanged, true);
            app.StartTestButton.Text = 'Start Test';
            app.StartTestButton.FontSize = 24;
            app.StartTestButton.FontWeight = 'bold';
            app.StartTestButton.Position = [50 50 200 100];

            % Create ConnectPanel
            app.ConnectPanel = uipanel(app.FlexBenchAppUIFigure);
            app.ConnectPanel.BorderType = 'none';
            app.ConnectPanel.Position = [1125 650 375 170];

            % Create ConnectButton
            app.ConnectButton = uibutton(app.ConnectPanel, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.IconAlignment = 'center';
            app.ConnectButton.FontName = 'Britannic Bold';
            app.ConnectButton.FontSize = 24;
            app.ConnectButton.FontWeight = 'bold';
            app.ConnectButton.Position = [25 20 250 80];
            app.ConnectButton.Text = 'Connect';

            % Create BaudRateDropDown
            app.BaudRateDropDown = uidropdown(app.ConnectPanel);
            app.BaudRateDropDown.Items = {'9600', '115200', '250000'};
            app.BaudRateDropDown.Placeholder = '115200';
            app.BaudRateDropDown.Position = [189 120 80 30];
            app.BaudRateDropDown.Value = '9600';

            % Create PortDropDown
            app.PortDropDown = uidropdown(app.ConnectPanel);
            app.PortDropDown.Items = {''};
            app.PortDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PortDropDownOpening, true);
            app.PortDropDown.Placeholder = 'Port';
            app.PortDropDown.Position = [30 120 80 30];
            app.PortDropDown.Value = '';

            % Create ConnectLamp
            app.ConnectLamp = uilamp(app.ConnectPanel);
            app.ConnectLamp.Position = [310 105 50 50];
            app.ConnectLamp.Color = [0.502 0.502 0.502];

            % Create ResistancePanel
            app.ResistancePanel = uipanel(app.FlexBenchAppUIFigure);
            app.ResistancePanel.BorderType = 'none';
            app.ResistancePanel.TitlePosition = 'centertop';
            app.ResistancePanel.Position = [850 50 300 200];

            % Create ResistanceTestButton
            app.ResistanceTestButton = uibutton(app.ResistancePanel, 'state');
            app.ResistanceTestButton.ValueChangedFcn = createCallbackFcn(app, @ResistanceTestButtonValueChanged, true);
            app.ResistanceTestButton.Text = 'Resistance Test';
            app.ResistanceTestButton.FontSize = 24;
            app.ResistanceTestButton.FontWeight = 'bold';
            app.ResistanceTestButton.Position = [50 50 200 100];

            % Create FlexBenchLabel
            app.FlexBenchLabel = uilabel(app.FlexBenchAppUIFigure);
            app.FlexBenchLabel.BackgroundColor = [0.9608 0.9608 0.9608];
            app.FlexBenchLabel.HorizontalAlignment = 'center';
            app.FlexBenchLabel.FontName = 'Sitka Text';
            app.FlexBenchLabel.FontSize = 80;
            app.FlexBenchLabel.FontWeight = 'bold';
            app.FlexBenchLabel.Position = [800 515 700 100];
            app.FlexBenchLabel.Text = 'FlexBench';

            % Create Image
            app.Image = uiimage(app.FlexBenchAppUIFigure);
            app.Image.ScaleMethod = 'fill';
            app.Image.Position = [800 650 320 150];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'LogoUPM.png');

            % Show the figure after all components are created
            app.FlexBenchAppUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = FlexBenchApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.FlexBenchAppUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.FlexBenchAppUIFigure)
        end
    end
end