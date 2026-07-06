classdef FlexBenchApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        FlexBenchLabel              matlab.ui.control.Label
        ResistancePanel             matlab.ui.container.Panel
        ResistanceTestButton        matlab.ui.control.StateButton
        ConnectPanel                matlab.ui.container.Panel
        PortDropDown                matlab.ui.control.DropDown
        BaudRateDropDown            matlab.ui.control.DropDown
        ConnectLamp                 matlab.ui.control.Lamp
        ConnectButton               matlab.ui.control.Button
        TestPanel                   matlab.ui.container.Panel
        StartTestButton             matlab.ui.control.Button
        NCiclosLabel                matlab.ui.control.Label
        CycleNumberEditField        matlab.ui.control.NumericEditField
        NFilterIntervalEditField    matlab.ui.control.NumericEditField
        NFilterIntervalLabel        matlab.ui.control.Label
        ParametersPanel             matlab.ui.container.Panel
        WidthEditField              matlab.ui.control.NumericEditField
        WidthcmEditFieldLabel       matlab.ui.control.Label
        InfillPatternDropDown       matlab.ui.control.DropDown
        InfillPatternDropDownLabel  matlab.ui.control.Label
        ThicknessEditField          matlab.ui.control.NumericEditField
        ThicknesscmEditFieldLabel   matlab.ui.control.Label
        LengthDropDown              matlab.ui.control.DropDown
        LengthDropDownLabel         matlab.ui.control.Label
        SetPanel                    matlab.ui.container.Panel
        SetHeightsButton            matlab.ui.control.Button
        SetMaxButton                matlab.ui.control.Button
        SetMinButton                matlab.ui.control.Button
        Set0Button                  matlab.ui.control.Button
        MovePanel                   matlab.ui.container.Panel
        DownButton                  matlab.ui.control.Button
        BigDownButton               matlab.ui.control.Button
        BigUpButton                 matlab.ui.control.Button
        UpButton                    matlab.ui.control.Button
        ComandEditField             matlab.ui.control.EditField
        MonitorTextArea             matlab.ui.control.TextArea
    end

    
    properties (Access = private)
    ESP32           % El puerto serie
    TimerDatos      % El cronómetro para pedir datos
    PauseTime = 3   % Duración de la pausa de estabilización
    
    % Registro de alturas del ciclo
    AlturaMax = 0
    AlturaMin = 0

    % Registro de estado de paneles
    estadoPrevioSet
    estadoPrevioMove
    estadoPrevioTest
    estadoPrevioParam

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
                        uialert(app.UIFigure, "MIN HEIGHT must be greater or equal than ZERO.", "Calibration error");
                    end
        
                % 3. Recepción y Validación de MÁXIMO
                elseif startsWith(mensaje, "MAX:")
                    val = str2double(extractAfter(mensaje, "MAX:"));
                    
                    if val > app.AlturaMin
                        app.AlturaMax = val;
                        app.SetMaxButton.Enable = 'off';
                        app.SetHeightsButton.Enable = 'on'; % Re-habilitamos por si se quiere recalibrar
                        app.TestPanel.Enable = "on";
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; 
                            "> MAXIMUM set at: " + string(val) ;"> Test Ready"];
                    else
                        uialert(app.UIFigure, "MAX HEIGHT must be greater than MIN HEIGHT.", "Calibration error");
                    end

                % 4. Resistencia
                elseif startsWith(mensaje, "RES")
                    % Extraemos el número de forma segura
                    numeros = regexp(mensaje, '-?\d+\.?\d*', 'match'); 
                    if ~isempty(numeros)
                        resistencia = str2double(numeros{1});
                    end
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
            app.SetPanel.Enable = "off";
            app.MovePanel.Enable = "off";
            app.TestPanel.Enable = "off";
            app.ResistancePanel.Enable = "off";
            puertos = serialportlist();
            app.PortDropDown.Items = puertos;
            
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

               %Habilitamos los paneles básicos
                app.ResistancePanel.Enable = "on";
                app.SetPanel.Enable = "on";
                app.MovePanel.Enable = "on";
                
            catch ME
                % Si algo falla, sacamos una alerta
                uialert(app.UIFigure, "Connection error: " + ME.message, "Connection Error");
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
                uialert(app.UIFigure, "Connect the port first.", "Error");
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
            writeline(app.ESP32,"U5"); %Manda subir 5 steps
        end

        % Button pushed function: DownButton
        function DownButtonPushed(app, event)
            writeline(app.ESP32,"D5") %Manda bajar 5 steps
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
            app.Set0Button.Enable = 'on';
            app.SetHeightsButton.Enable = 'off';
            
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> CALIBRATION MODE ACTIVATED"];
        end

        % Button pushed function: Set0Button
        function Set0ButtonPushed(app, event)
            if ~isempty(app.ESP32) && isvalid(app.ESP32)
                writeline(app.ESP32, "S"); % Manda establecer la posición como nuevo cero
                app.Set0Button.Enable = 'off';
            end
        end

        % Button pushed function: BigUpButton
        function BigUpButtonPushed(app, event)
            writeline(app.ESP32,"U50")  %Manda subir 50 steps
        end

        % Button pushed function: BigDownButton
        function BigDownButtonPushed(app, event)
            writeline(app.ESP32,"D50")  %Manda bajar 50 steps
        end

        % Button pushed function: StartTestButton
        function StartTestButtonPushed(app, event)
    
      % ============================= 
      % 0. COMPROBACIONES INICIALES
      % =============================
        % .1 Comprobación del puerto
        if isempty(app.ESP32) || ~isvalid(app.ESP32)
            uialert(app.UIFigure, "Please, connect first the port", "Connection error");
            return;
        end
        
        % .2 Comprobación de Ciclos
        nCiclos = app.CycleNumberEditField.Value;
        if nCiclos <= 0 
            uialert(app.UIFigure, "The number of cycles must be greater than 0.", "Test parameters incomplete");
            return;
        end
        
        % .3 Comprobación de los datos de la probeta
        if app.WidthEditField.Value <= 0
            uialert(app.UIFigure, "Please, enter the specimen width value.", "Specimen data incomplete");
            return;
        end
        
        if app.ThicknessEditField.Value <= 0
            uialert(app.UIFigure, "Please, enter the specimen thickness value.", "Specimen data incomplete");
            return;
        end
        
        valPattern = string(app.InfillPatternDropDown.Value);
        if ismissing(valPattern) || valPattern == ""
            uialert(app.UIFigure, "Please, select an Infill Pattern.", "Specimen data incomplete");
            return;
        end
        
        
        try

          %=====================================
          % 1. BLOQUEAR INTERFAZ (Modo Ensayo)
          % ====================================
            % .1 Bloqueo Botones
            app.MovePanel.Enable ="off";
            app.SetPanel.Enable ="off";
            app.TestPanel.Enable ="off";
            app.ResistancePanel.Enable ="off";
            app.ParametersPanel.Enable ="off";

            % .2 Bloqueo de la funcionalidad de comandos
            configureCallback(app.ESP32, "off");
            flush(app.ESP32); 
            
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Preparing: Going to max height..."];
            scroll(app.MonitorTextArea, 'bottom');
            
          % ===================
          % 2. AJUSTE INICIAL
          % ===================
            % .1 Obtención de la posicion actual
            writeline(app.ESP32, "P"); 
            posActual = NaN;
            while true
                resp = readline(app.ESP32);
                if startsWith(resp, "POS")
                    numeros = regexp(resp, '-?\d+\.?\d*', 'match'); 
                    posActual = str2double(numeros{1});
                    break;
                end
            end
            % .2 Cálculo de distacia a MAX y dirección
            posicionPlana = (app.AlturaMax+app.AlturaMin) / 2;
            amplitudMedia = (app.AlturaMax - app.AlturaMin) / 2;

            distancia = posicionPlana - posActual;
           
            % .3 Espera a la llegada a MAX

            if distancia > 0
                writeline(app.ESP32, "U" + string(distancia));
            elseif distancia < 0
                writeline(app.ESP32, "D" + string(-distancia));
            end
                
            if distancia ~= 0
                while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED")
                end
            end

          % ================================
          % 3. BUCLE DE ENSAYO (STOP & GO)
          % ================================

            % .1 Configuración previa
            amplitud = app.AlturaMax - app.AlturaMin;
            pasosMuestreo = 1; 
            datosEnsayo = [];
            t_inicio = tic; % Inicio cronometro interno
            
            % .2 Bucle
            for i = 1:nCiclos
                
                nuevaLinea = string(sprintf("> TEST: Cycle %d/%d (0.0%%)", i, nCiclos));
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; nuevaLinea];
                scroll(app.MonitorTextArea, 'bottom');

                pasosTotalesCiclo = amplitudMedia * 4;
                pasosDados = 0;
                
                % ----------------------
                % .2a SUBIDA 50% → 100% 
                % ----------------------
                pasosRestantes = amplitudMedia;
                while pasosRestantes > 0
                    pasos = min(pasosMuestreo, pasosRestantes);
                    
                    % a.1 Subir
                    writeline(app.ESP32, "U" + string(pasos));

                    % a.2 Espera a la llegada
                    while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED"); end

                    % a.3 Lectura de posición, resitencia y tiempo
                    writeline(app.ESP32, "P");
                    posTemp = NaN;
                    while true
                        resp = readline(app.ESP32);
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

                    tiempoActual = toc(t_inicio);

                    % a.4 Guardado en vector y actualización de pasos restantes
                    datosEnsayo = [datosEnsayo; i, posTemp, resTemp, tiempoActual];
                    pasosRestantes = pasosRestantes - pasos;
                    pasosDados = pasosDados + pasos;
                    
                    % a.5 Actualización dinémica del porcentaje
                    progreso = ((pasosDados) / (pasosTotalesCiclo)) * 100;
                    
                    lineas = string(app.MonitorTextArea.Value);
                    lineas(end) = sprintf("> TEST: Cycle %d/%d (%.1f%%)", i, nCiclos, progreso);
                    app.MonitorTextArea.Value = cellstr(lineas);
                    drawnow; 
                end
                
                % ---------------------------------------
                % .2b Pausa de estabilización en Máximo 
                % ---------------------------------------

                % b.1 Mostrar por pantalla
                lineas = string(app.MonitorTextArea.Value);
                lineas(end) = sprintf("> TEST: Cycle %d/%d (50.0%%)", i, nCiclos);
                lineas = [lineas; "  -> Stabilizing at Maximum (3s)..."];   %Línea temporal
                app.MonitorTextArea.Value = cellstr(lineas);
                scroll(app.MonitorTextArea, 'bottom');
                drawnow;
                
                % b.2 Bucle activo de lectura
                t_pausa = tic;

                while toc(t_pausa) < app.PauseTime
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
                    
                    tiempoActual = toc(t_inicio);
                    datosEnsayo = [datosEnsayo; i, posTemp, resTemp, tiempoActual];
                    drawnow; 
                end
                
                % b.3 Borramos la línea temporal
                lineas = string(app.MonitorTextArea.Value);
                lineas(end) = []; 
                app.MonitorTextArea.Value = cellstr(lineas);
                drawnow;
                
                % ----------------------
                % .2c BAJADA 100% → 0% 
                % ----------------------

                pasosRestantes = amplitudMedia*2;
                while pasosRestantes > 0
                    pasos = min(pasosMuestreo, pasosRestantes);
                    
                    % c.1 Bajar
                    writeline(app.ESP32, "D" + string(pasos));

                    % c.2 Espera a la llegada
                    while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED")
                    end
                    
                    % c.3 Lectura de posición, resitencia y tiempo
                    writeline(app.ESP32, "P");
                    posTemp = NaN;
                    while true
                        resp = readline(app.ESP32);
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
                    
                    tiempoActual = toc(t_inicio);

                    % c.4 Guardado en vector y actualización de pasos restantes
                    datosEnsayo = [datosEnsayo; i, posTemp, resTemp, tiempoActual];
                    pasosRestantes = pasosRestantes - pasos;
                    pasosDados = pasosDados + pasos;
                    
                    % c.5 Actualización dinémica del porcentaje
                    progreso = (pasosDados / pasosTotalesCiclo) * 100;
                    lineas = string(app.MonitorTextArea.Value);
                    lineas(end) = sprintf("> TEST: Cycle %d/%d (%.1f%%)", i, nCiclos, progreso);
                    app.MonitorTextArea.Value = cellstr(lineas);
                    drawnow; 
                end

                % ---------------------------------------
                % .2d Pausa de estabilización en Máximo 
                % ---------------------------------------

                % d.1 Mostrar por pantalla
                lineas = string(app.MonitorTextArea.Value);
                lineas = [lineas; "  -> Stabilizing at Minimum (3s)..."];
                app.MonitorTextArea.Value = cellstr(lineas);
                scroll(app.MonitorTextArea, 'bottom');
                drawnow;
                
                % d.2 Bucle activo de lectura
                t_pausa = tic;
                while toc(t_pausa) < app.PauseTime
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
                    
                    tiempoActual = toc(t_inicio);
                    datosEnsayo = [datosEnsayo; i, posTemp, resTemp, tiempoActual];
                    drawnow; 
                end
                
                % d.3 Borramos la línea temporal
                lineas = string(app.MonitorTextArea.Value);
                lineas(end) = [];
                app.MonitorTextArea.Value = cellstr(lineas);
                drawnow;

                % ---------------------
                % .2e SUBIDA 0% → 50%
                % ---------------------

                pasosRestantes = amplitudMedia; 
                while pasosRestantes > 0

                    pasos = min(pasosMuestreo, pasosRestantes);

                    %e.1 Subir
                    writeline(app.ESP32, "U" + string(pasos));

                    % e.2 Espera a la llegada
                    while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED"); end

                    % e.3 Lectura de posición, resitencia y tiempo
                    writeline(app.ESP32, "P"); posTemp = NaN;
                    while true
                        resp = readline(app.ESP32)
                        if startsWith(resp, "POS:")
                            num = regexp(resp, '-?\d+\.?\d*', 'match')
                            posTemp = str2double(num{1})
                            break;
                        end
                    end

                    writeline(app.ESP32, "R"); resTemp = NaN;
                    while true
                        resp = readline(app.ESP32)
                        if startsWith(resp, "RES:")
                            num = regexp(resp, '-?\d+\.?\d*', 'match')
                            resTemp = str2double(num{1})
                            break
                        end
                    end

                    tiempoActual = toc(t_inicio);

                    % e.4 Guardado en vector y actualización de pasos restantes
                    datosEnsayo = [datosEnsayo; i, posTemp, resTemp, tiempoActual];
                    pasosRestantes = pasosRestantes - pasos;
                    pasosDados = pasosDados + pasos;
                    
                    % e.5 Actualización dinémica del porcentaje
                    progreso = (pasosDados / pasosTotalesCiclo) * 100;
                    lineas = string(app.MonitorTextArea.Value);
                    lineas(end) = sprintf("> TEST: Cycle %d/%d (%.1f%%)", i, nCiclos, progreso);
                    app.MonitorTextArea.Value = cellstr(lineas); drawnow;


                % ---------------------------------------
                % .2f Pausa de estabilización en Medio 
                % ---------------------------------------

                    lineas = string(app.MonitorTextArea.Value);
                    lineas = [lineas; "  -> Stabilizing at Flat Position..."];
                    app.MonitorTextArea.Value = cellstr(lineas); scroll(app.MonitorTextArea, 'bottom');
                    drawnow;
                    
                    t_pausa = tic;
                    while toc(t_pausa) < app.PauseTime
                        writeline(app.ESP32, "R");
                        resTemp = NaN;
                        while true
                            resp = readline(app.ESP32)
                            if startsWith(resp, "RES:")
                                num = regexp(resp, '-?\d+\.?\d*', 'match')
                                resTemp = str2double(num{1})
                                break
                            end
                        end
                        tiempoActual = toc(t_inicio);
                        datosEnsayo = [datosEnsayo; i, posTemp, resTemp, tiempoActual]
                        drawnow; 
                    end
                    lineas = string(app.MonitorTextArea.Value); lineas(end) = []; 
                    lineas(end) = sprintf("> TEST: Cycle %d/%d (100.0%%) - Completed", i, nCiclos);
                    app.MonitorTextArea.Value = cellstr(lineas);
                    drawnow;
                end
                
            end
            % =======================
            % 5. ENSAYO FIN Y EXCEL
            % =======================

            % .1 Mostrar por pantalla
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> TEST COMPLETED. Processing data and generating Excel..."];
            scroll(app.MonitorTextArea, 'bottom');
            drawnow; 
            
            % ------------------------------------
            % .a Cálculo de la resistencia media
            % ------------------------------------

            resistenciaMedia = movmean(datosEnsayo(:, 3), app.NFilterIntervalEditField.Value);
            datosCompletos = [datosEnsayo, resistenciaMedia]; % Columnas: [Ciclo, Pos, Res, T, Res_Media]
            
            % ----------------------
            % .B Gauge Factor (GF)
            % ----------------------
            
            % B.1 Datos mecánicos
            modulo = 1;
            dientes = 60;
            diametroPrimitivo = modulo * dientes; 
            avancePorVuelta = pi * diametroPrimitivo; 
            
            pasosPorVueltaMotor = 200;
            microstepping = 256;
            avancePorPaso = avancePorVuelta / (pasosPorVueltaMotor * microstepping); % mm/paso
            thickness_mm = app.ThicknessEditField.Value * 10;
            
            % B.2 Longitud inicial de la probeta (L0)
            L0_cm = str2double(extractBefore(string(app.LengthDropDown.Value), " "));
            L0_mm = L0_cm * 10;
            
            %  Preparamos las nuevas columnas
            columnaDeformacion = zeros(size(datosCompletos, 1), 1);
            columnaGF = zeros(size(datosCompletos, 1), 1);
            
            % B.3 R0 dinámico ciclo a ciclo
            for j = 1:nCiclos
                idxCiclo = find(datosCompletos(:, 1) == j);
                if ~isempty(idxCiclo)
                    
                    R0 = datosCompletos(idxCiclo(1), 5); 
                    Pos0 = datosCompletos(idxCiclo(1), 2); 
                    
                    for k = 1:length(idxCiclo)
                        fila = idxCiclo(k);
                        
                        % Deflexión
                        incrementoPasos = abs(datosCompletos(fila, 2) - Pos0);
                        deflexion_mm = incrementoPasos * avancePorPaso; % Esto equivale a la flecha de pandeo
                        
                        % DEFORMACIÓN UNITARIA DE FLEXIÓN (Strain / Epsilon)
                        epsilon = (6 * deflexion_mm * grosor) / L0^2
                        
                        columnaDeformacion(fila) = epsilon;
                        
                        % Gauge Factor
                        deltaR = datosCompletos(fila, 5) - R0;
                        variacionRelativaR = deltaR / R0;
                        
                        if epsilon == 0
                            columnaGF(fila) = NaN; % Evitamos dividir por 0
                        else
                            columnaGF(fila) = variacionRelativaR / epsilon;
                        end
                    end
                end
            end
            
            % Unimos todo en la matriz final (7 columnas ahora)
            datosCompletos = [datosCompletos, columnaDeformacion, columnaGF];
            
            % TABLA 1: Datos del ensayo actualizados
            tablaDatos = array2table(datosCompletos, 'VariableNames', ...
                {'Cycle', 'Position', 'Resistance', 'Time', 'Average_Resistance', 'Strain', 'Gauge_Factor'});
            
            % --- RECOPILACIÓN DE METADATOS DE LA PROBETA ---
            valLength    = string(app.LengthDropDown.Value);
            valWidth     = string(app.WidthEditField.Value);
            valThickness = string(app.ThicknessEditField.Value);
            valPattern   = string(app.InfillPatternDropDown.Value);
            
            Attributes = {'Length'; 'Width (cm)'; 'Thickness (mm)'; 'Infill Pattern'};
            Values = {valLength; valWidth; valThickness; valPattern};
            tablaInfo = table(Attributes, Values, 'VariableNames', {'Attribute', 'Value'});
            
            % --- GUARDADO DE ARCHIVOS ---
            rutaDestino = "C:\Users\santi\OneDrive\Documentos\UPM\4º\TFG\Datos";
            if ~exist(rutaDestino, 'dir')
                mkdir(rutaDestino);
            end
            
            fechaStr = char(datetime('now', 'Format', 'dd-MM-yy     HH;mm;ss'));
            nombreArchivo = fullfile(rutaDestino, "Test_" + fechaStr + ".xlsx"); 
            
            writetable(tablaDatos, nombreArchivo, 'Sheet', 'Test_Data');
            writetable(tablaInfo, nombreArchivo, 'Sheet', 'Specimen_Info');
            
            % --- GRÁFICOS COM ---
            try
                Excel = actxserver('Excel.Application');
                Workbook = Excel.Workbooks.Open(nombreArchivo);
                Sheet = Workbook.Sheets.Item('Test_Data'); % Apuntamos a la hoja de datos
                
                numFilas = size(datosCompletos, 1) + 1; 
                
                % --- CÁLCULO DE ESCALA DINÁMICA (Resistencia) ---
                mediaRes = mean(datosCompletos(:, 5), 'omitnan');
                escalaMin = round((mediaRes - 200) / 100) * 100;
                escalaMax = round((mediaRes + 200) / 100) * 100;
                
                % ==========================================
                % GRÁFICO 1: Resistencia vs Tiempo
                % ==========================================
                Grafico1 = Excel.Charts.Add;
                Grafico1.ChartType = 'xlXYScatter'; 
                while Grafico1.SeriesCollection.Count > 0
                    Grafico1.SeriesCollection.Item(1).Delete;
                end
                rangoX1 = Sheet.Range(sprintf('D2:D%d', numFilas)); % Tiempo
                rangoY1 = Sheet.Range(sprintf('E2:E%d', numFilas)); % Resistencia Media
                Serie1 = Grafico1.SeriesCollection.NewSeries;
                Serie1.XValues = rangoX1;
                Serie1.Values = rangoY1;
                Serie1.MarkerStyle = 8; 
                Serie1.MarkerSize = 2;  
                Grafico1.HasTitle = true;
                Grafico1.ChartTitle.Text = 'Resistance vs Time (Filtered)';
                Grafico1.HasLegend = false; 
                Grafico1.Axes(1).HasTitle = true;
                Grafico1.Axes(1).AxisTitle.Text = 'Time (s)';
                Grafico1.Axes(2).HasTitle = true;
                Grafico1.Axes(2).AxisTitle.Text = 'Average Resistance (Ohms)';
                Grafico1.Axes(2).MinimumScale = escalaMin;
                Grafico1.Axes(2).MaximumScale = escalaMax;
                Grafico1.Location(2, Sheet.Name); 
                
                Shape1 = Sheet.Shapes.Item(Sheet.Shapes.Count);
                Shape1.Width = 600;  Shape1.Height = 350;
                Shape1.Top = 20;     Shape1.Left = 550; 
                
                % ==========================================
                % GRÁFICO 2: Histéresis Multiciclo
                % ==========================================
                Grafico2 = Excel.Charts.Add;
                Grafico2.ChartType = 'xlXYScatterLinesNoMarkers'; 
                while Grafico2.SeriesCollection.Count > 0
                    Grafico2.SeriesCollection.Item(1).Delete;
                end
                for c = 1:nCiclos
                    filasCiclo = find(datosCompletos(:, 1) == c);
                    if ~isempty(filasCiclo)
                        filaInicio = filasCiclo(1) + 1;
                        filaFin = filasCiclo(end) + 1;
                        rangoX2 = Sheet.Range(sprintf('E%d:E%d', filaInicio, filaFin)); % Resistencia
                        rangoY2 = Sheet.Range(sprintf('B%d:B%d', filaInicio, filaFin)); % Posicion
                        Serie2 = Grafico2.SeriesCollection.NewSeries;
                        Serie2.XValues = rangoX2;
                        Serie2.Values = rangoY2;
                        Serie2.Name = sprintf('Cycle %d', c);
                        Serie2.Format.Line.Weight = 1.0;
                    end
                end
                Grafico2.HasTitle = true;
                Grafico2.ChartTitle.Text = 'Hysteresis: Position vs Resistance';
                Grafico2.HasLegend = true; 
                Grafico2.Axes(1).HasTitle = true;
                Grafico2.Axes(1).AxisTitle.Text = 'Average Resistance (Ohms)';
                Grafico2.Axes(2).HasTitle = true;
                Grafico2.Axes(2).AxisTitle.Text = 'Position (Steps)';
                Grafico2.Axes(1).MinimumScale = escalaMin;
                Grafico2.Axes(1).MaximumScale = escalaMax;
                Grafico2.Location(2, Sheet.Name); 
                
                Shape2 = Sheet.Shapes.Item(Sheet.Shapes.Count);
                Shape2.Width = 600;   Shape2.Height = 350;
                Shape2.Top = Shape1.Top + Shape1.Height + 20; 
                Shape2.Left = 550;
                
                % ==========================================
                % GRÁFICO 3: Gauge Factor vs Strain
                % ==========================================
                Grafico3 = Excel.Charts.Add;
                Grafico3.ChartType = 'xlXYScatter'; 
                while Grafico3.SeriesCollection.Count > 0
                    Grafico3.SeriesCollection.Item(1).Delete;
                end
                for c = 1:nCiclos
                    filasCiclo = find(datosCompletos(:, 1) == c);
                    if ~isempty(filasCiclo)
                        filaInicio = filasCiclo(1) + 1;
                        filaFin = filasCiclo(end) + 1;
                        rangoX3 = Sheet.Range(sprintf('F%d:F%d', filaInicio, filaFin)); % Strain
                        rangoY3 = Sheet.Range(sprintf('G%d:G%d', filaInicio, filaFin)); % GF
                        Serie3 = Grafico3.SeriesCollection.NewSeries;
                        Serie3.XValues = rangoX3;
                        Serie3.Values = rangoY3;
                        Serie3.Name = sprintf('Cycle %d', c);
                        Serie3.MarkerStyle = 8; 
                        Serie3.MarkerSize = 3;  
                    end
                end
                Grafico3.HasTitle = true;
                Grafico3.ChartTitle.Text = 'Sensitivity: Gauge Factor vs Strain';
                Grafico3.HasLegend = true; 
                Grafico3.Axes(1).HasTitle = true;
                Grafico3.Axes(1).AxisTitle.Text = 'Strain (ε)';
                Grafico3.Axes(2).HasTitle = true;
                Grafico3.Axes(2).AxisTitle.Text = 'Gauge Factor (GF)';
                Grafico3.Location(2, Sheet.Name); 
                
                % Posicionamos el tercer gráfico justo debajo del segundo
                Shape3 = Sheet.Shapes.Item(Sheet.Shapes.Count);
                Shape3.Width = 600;   Shape3.Height = 350;
                Shape3.Top = Shape2.Top + Shape2.Height + 20; 
                Shape3.Left = 550;
                
                Workbook.Save;
                Workbook.Close;
                Excel.Quit;
                delete(Excel);
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Correctly saved: " + nombreArchivo];
                scroll(app.MonitorTextArea, 'bottom');
            catch ME
                if exist('Excel', 'var')
                    Excel.Quit;
                    delete(Excel);
                end
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Warning: Native charting failed. " + ME.message];
                scroll(app.MonitorTextArea, 'bottom');
            end
        
            % --- 6. RESTAURAR LA NORMALIDAD ---
            app.MovePanel.Enable ="on";
            app.SetPanel.Enable ="on";
            app.TestPanel.Enable ="on";
            app.ResistancePanel.Enable ="on";
            app.ParametersPanel.Enable ="on";
    
            configureCallback(app.ESP32, "terminator", @app.leerMensajeSerie);
            end
        end

        % Value changed function: ResistanceTestButton
        function ResistanceTestButtonValueChanged(app, event)
            % 0. Verificar conexión
            if isempty(app.ESP32) || ~isvalid(app.ESP32)
                app.ResistanceTestButton.Value = false;
                uialert(app.UIFigure, "Connect first the port.", "Warning");
                return;
            end
            if app.ResistanceTestButton.Value % --- MODO SPAM ACTIVADO ---
                
                %Cambio visual al boton
                app.ResistanceTestButton.Text = 'STOP';
                app.ResistanceTestButton.BackgroundColor = [1 0.4 0.4]; % Color rojizo
                
                % 1. GUARDAMOS EL ESTADO ACTUAL DE LOS PANELES
                app.estadoPrevioSet   = app.SetPanel.Enable;
                app.estadoPrevioMove  = app.MovePanel.Enable;
                app.estadoPrevioTest  = app.TestPanel.Enable;
                app.estadoPrevioParam = app.ParametersPanel.Enable;
                
                % 2. BLOQUEAMOS TODO LO DEMÁS
                app.SetPanel.Enable        = "off";
                app.MovePanel.Enable       = "off";
                app.TestPanel.Enable       = "off";
                app.ParametersPanel.Enable = "off";
                
                % 3. CREAMOS EL METRÓNOMO Y LO ARRANCAMOS
                app.TimerDatos = timer('ExecutionMode', 'fixedRate', 'Period', 0.1, ...
                                       'TimerFcn', @(~,~) writeline(app.ESP32, "R"));
                start(app.TimerDatos);
                
            else % --- MODO NORMAL (APAGADO) ---
                app.ResistanceTestButton.Text = 'Resistance Test';
                app.ResistanceTestButton.BackgroundColor = [0.96 0.96 0.96]; % Gris normal
                
                % 1. PARAMOS Y DESTRUIMOS EL METRÓNOMO
                if ~isempty(app.TimerDatos) && isvalid(app.TimerDatos)
                    stop(app.TimerDatos);
                    delete(app.TimerDatos);
                end
                
                % 2. RESTAURAMOS LA MEMORIA EXACTA QUE HABÍA ANTES
                app.SetPanel.Enable        = app.estadoPrevioSet;
                app.MovePanel.Enable       = app.estadoPrevioMove;
                app.TestPanel.Enable       = app.estadoPrevioTest;
                app.ParametersPanel.Enable = app.estadoPrevioParam;
                
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Resistance test finished."];
                scroll(app.MonitorTextArea, 'bottom');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [0 0 1540 845];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';
            app.UIFigure.WindowStyle = 'modal';

            % Create MonitorTextArea
            app.MonitorTextArea = uitextarea(app.UIFigure);
            app.MonitorTextArea.Editable = 'off';
            app.MonitorTextArea.FontName = 'Consolas';
            app.MonitorTextArea.FontSize = 18;
            app.MonitorTextArea.FontColor = [0 1 0];
            app.MonitorTextArea.BackgroundColor = [0 0 0];
            app.MonitorTextArea.Position = [20 60 500 750];
            app.MonitorTextArea.Value = {'CONSOLE:'};

            % Create ComandEditField
            app.ComandEditField = uieditfield(app.UIFigure, 'text');
            app.ComandEditField.ValueChangedFcn = createCallbackFcn(app, @ComandEditFieldValueChanged, true);
            app.ComandEditField.Position = [20 20 500 30];

            % Create MovePanel
            app.MovePanel = uipanel(app.UIFigure);
            app.MovePanel.AutoResizeChildren = 'off';
            app.MovePanel.BorderType = 'none';
            app.MovePanel.Position = [1275 75 200 200];

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
            app.SetPanel = uipanel(app.UIFigure);
            app.SetPanel.AutoResizeChildren = 'off';
            app.SetPanel.BorderType = 'none';
            app.SetPanel.Position = [925 75 300 200];

            % Create Set0Button
            app.Set0Button = uibutton(app.SetPanel, 'push');
            app.Set0Button.ButtonPushedFcn = createCallbackFcn(app, @Set0ButtonPushed, true);
            app.Set0Button.FontSize = 18;
            app.Set0Button.Enable = 'off';
            app.Set0Button.Position = [15 20 80 50];
            app.Set0Button.Text = 'Set0';

            % Create SetMinButton
            app.SetMinButton = uibutton(app.SetPanel, 'push');
            app.SetMinButton.ButtonPushedFcn = createCallbackFcn(app, @SetMinButtonPushed, true);
            app.SetMinButton.FontSize = 18;
            app.SetMinButton.Enable = 'off';
            app.SetMinButton.Position = [110 20 80 50];
            app.SetMinButton.Text = 'SetMin';

            % Create SetMaxButton
            app.SetMaxButton = uibutton(app.SetPanel, 'push');
            app.SetMaxButton.ButtonPushedFcn = createCallbackFcn(app, @SetMaxButtonPushed, true);
            app.SetMaxButton.FontSize = 18;
            app.SetMaxButton.Enable = 'off';
            app.SetMaxButton.Position = [205 20 80 50];
            app.SetMaxButton.Text = 'SetMax';

            % Create SetHeightsButton
            app.SetHeightsButton = uibutton(app.SetPanel, 'push');
            app.SetHeightsButton.ButtonPushedFcn = createCallbackFcn(app, @SetHeightsButtonPushed, true);
            app.SetHeightsButton.FontSize = 18;
            app.SetHeightsButton.Position = [50 101 200 80];
            app.SetHeightsButton.Text = 'Set Heights';

            % Create ParametersPanel
            app.ParametersPanel = uipanel(app.UIFigure);
            app.ParametersPanel.BorderType = 'none';
            app.ParametersPanel.TitlePosition = 'centertop';
            app.ParametersPanel.Position = [575 75 300 200];

            % Create LengthDropDownLabel
            app.LengthDropDownLabel = uilabel(app.ParametersPanel);
            app.LengthDropDownLabel.HorizontalAlignment = 'center';
            app.LengthDropDownLabel.Position = [30 141 60 25];
            app.LengthDropDownLabel.Text = 'Length';

            % Create LengthDropDown
            app.LengthDropDown = uidropdown(app.ParametersPanel);
            app.LengthDropDown.Items = {'5 cm', '10 cm', '15 cm'};
            app.LengthDropDown.Position = [30 111 60 25];
            app.LengthDropDown.Value = '5 cm';

            % Create ThicknesscmEditFieldLabel
            app.ThicknesscmEditFieldLabel = uilabel(app.ParametersPanel);
            app.ThicknesscmEditFieldLabel.HorizontalAlignment = 'center';
            app.ThicknesscmEditFieldLabel.Position = [160 56 90 25];
            app.ThicknesscmEditFieldLabel.Text = 'Thickness (cm)';

            % Create ThicknessEditField
            app.ThicknessEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.ThicknessEditField.Position = [160 26 90 25];

            % Create InfillPatternDropDownLabel
            app.InfillPatternDropDownLabel = uilabel(app.ParametersPanel);
            app.InfillPatternDropDownLabel.HorizontalAlignment = 'center';
            app.InfillPatternDropDownLabel.Position = [128 141 155 25];
            app.InfillPatternDropDownLabel.Text = 'Infill Pattern';

            % Create InfillPatternDropDown
            app.InfillPatternDropDown = uidropdown(app.ParametersPanel);
            app.InfillPatternDropDown.Items = {'Gyroid (G)', 'Concentric (O)', 'Cross (+)', 'Aligned Rectilinear (r)'};
            app.InfillPatternDropDown.Position = [128 111 155 25];
            app.InfillPatternDropDown.Value = 'Gyroid (G)';

            % Create WidthcmEditFieldLabel
            app.WidthcmEditFieldLabel = uilabel(app.ParametersPanel);
            app.WidthcmEditFieldLabel.HorizontalAlignment = 'center';
            app.WidthcmEditFieldLabel.Position = [30 56 70 25];
            app.WidthcmEditFieldLabel.Text = 'Width (cm)';

            % Create WidthEditField
            app.WidthEditField = uieditfield(app.ParametersPanel, 'numeric');
            app.WidthEditField.Position = [30 26 70 25];

            % Create TestPanel
            app.TestPanel = uipanel(app.UIFigure);
            app.TestPanel.BorderType = 'none';
            app.TestPanel.Position = [675 350 300 200];

            % Create NFilterIntervalLabel
            app.NFilterIntervalLabel = uilabel(app.TestPanel);
            app.NFilterIntervalLabel.HorizontalAlignment = 'center';
            app.NFilterIntervalLabel.Position = [170 56 90 25];
            app.NFilterIntervalLabel.Text = 'N Filter Interval';

            % Create NFilterIntervalEditField
            app.NFilterIntervalEditField = uieditfield(app.TestPanel, 'numeric');
            app.NFilterIntervalEditField.HorizontalAlignment = 'center';
            app.NFilterIntervalEditField.Position = [170 26 90 25];
            app.NFilterIntervalEditField.Value = 20;

            % Create CycleNumberEditField
            app.CycleNumberEditField = uieditfield(app.TestPanel, 'numeric');
            app.CycleNumberEditField.HorizontalAlignment = 'center';
            app.CycleNumberEditField.Position = [40 26 80 25];
            app.CycleNumberEditField.Value = 10;

            % Create NCiclosLabel
            app.NCiclosLabel = uilabel(app.TestPanel);
            app.NCiclosLabel.HorizontalAlignment = 'center';
            app.NCiclosLabel.Position = [40 56 80 25];
            app.NCiclosLabel.Text = 'Cycle Number';

            % Create StartTestButton
            app.StartTestButton = uibutton(app.TestPanel, 'push');
            app.StartTestButton.ButtonPushedFcn = createCallbackFcn(app, @StartTestButtonPushed, true);
            app.StartTestButton.FontSize = 24;
            app.StartTestButton.FontWeight = 'bold';
            app.StartTestButton.Position = [50 101 200 80];
            app.StartTestButton.Text = 'Start Test';

            % Create ConnectPanel
            app.ConnectPanel = uipanel(app.UIFigure);
            app.ConnectPanel.AutoResizeChildren = 'off';
            app.ConnectPanel.BorderType = 'none';
            app.ConnectPanel.Position = [1100 630 400 170];

            % Create ConnectButton
            app.ConnectButton = uibutton(app.ConnectPanel, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.IconAlignment = 'center';
            app.ConnectButton.FontName = 'Britannic Bold';
            app.ConnectButton.FontSize = 24;
            app.ConnectButton.FontWeight = 'bold';
            app.ConnectButton.Position = [30 75 250 80];
            app.ConnectButton.Text = 'Connect';

            % Create ConnectLamp
            app.ConnectLamp = uilamp(app.ConnectPanel);
            app.ConnectLamp.Position = [325 90 50 50];
            app.ConnectLamp.Color = [0.502 0.502 0.502];

            % Create BaudRateDropDown
            app.BaudRateDropDown = uidropdown(app.ConnectPanel);
            app.BaudRateDropDown.Items = {'9600', '115200', '250000'};
            app.BaudRateDropDown.Placeholder = '115200';
            app.BaudRateDropDown.Position = [180 20 100 30];
            app.BaudRateDropDown.Value = '9600';

            % Create PortDropDown
            app.PortDropDown = uidropdown(app.ConnectPanel);
            app.PortDropDown.Items = {''};
            app.PortDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PortDropDownOpening, true);
            app.PortDropDown.Placeholder = 'Available Ports';
            app.PortDropDown.Position = [30 20 125 30];
            app.PortDropDown.Value = '';

            % Create ResistancePanel
            app.ResistancePanel = uipanel(app.UIFigure);
            app.ResistancePanel.AutoResizeChildren = 'off';
            app.ResistancePanel.BorderType = 'none';
            app.ResistancePanel.TitlePosition = 'centertop';
            app.ResistancePanel.Position = [1075 350 300 200];

            % Create ResistanceTestButton
            app.ResistanceTestButton = uibutton(app.ResistancePanel, 'state');
            app.ResistanceTestButton.ValueChangedFcn = createCallbackFcn(app, @ResistanceTestButtonValueChanged, true);
            app.ResistanceTestButton.Text = 'Resistance Test';
            app.ResistanceTestButton.FontSize = 24;
            app.ResistanceTestButton.FontWeight = 'bold';
            app.ResistanceTestButton.Position = [50 100 200 80];

            % Create FlexBenchLabel
            app.FlexBenchLabel = uilabel(app.UIFigure);
            app.FlexBenchLabel.BackgroundColor = [0.8 0.8 0.8];
            app.FlexBenchLabel.HorizontalAlignment = 'center';
            app.FlexBenchLabel.FontName = 'Dubai Medium';
            app.FlexBenchLabel.FontSize = 70;
            app.FlexBenchLabel.FontWeight = 'bold';
            app.FlexBenchLabel.Position = [610 665 400 100];
            app.FlexBenchLabel.Text = 'FlexBench';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = FlexBenchApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end