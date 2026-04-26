classdef FlexBenchApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        NTomascicloEditField       matlab.ui.control.NumericEditField
        NTomascicloEditFieldLabel  matlab.ui.control.Label
        NCiclosLabel               matlab.ui.control.Label
        BigUpButton                matlab.ui.control.Button
        BigDownButton              matlab.ui.control.Button
        SetHeigthsButton           matlab.ui.control.Button
        DownButton                 matlab.ui.control.Button
        UpButton                   matlab.ui.control.Button
        Set0Button                 matlab.ui.control.Button
        SetMinButton               matlab.ui.control.Button
        SetMaxButton               matlab.ui.control.Button
        ComandEditField            matlab.ui.control.EditField
        MonitorTextArea            matlab.ui.control.TextArea
        ConnectLamp                matlab.ui.control.Lamp
        ConnectButton              matlab.ui.control.Button
        BaudRateDropDown           matlab.ui.control.DropDown
        PortDropDown               matlab.ui.control.DropDown
        NCiclosEditField           matlab.ui.control.NumericEditField
        IniciarEnsayoButton        matlab.ui.control.Button
    end

    
    properties (Access = private)
    ESP32           % El puerto serie
    TimerDatos      % El cronómetro para pedir datos
    
    % Las alturas del ciclo
    AlturaMax = 0
    AlturaMin = 0
    
    end

    methods (Access = private)
        
        function leerMensajeSerie(app, src, ~)
            try
                mensaje = readline(src);
                
                % 1. Confirmación de CERO
                if startsWith(mensaje, "ZERO POSITION SET")
                    app.Set0Button.Enable = 'off';    % Bloquea el paso actual
                    app.SetMinButton.Enable = 'on';   % Habilita el siguiente
                    app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> CERO OK. MUEVA A MÍNIMO Y PULSE SetMin"];
        
                % 2. Recepción y Validación de MÍNIMO
                elseif startsWith(mensaje, "MIN:")
                    val = str2double(extractAfter(mensaje, "MIN:"));
                    
                    if val >= 0
                        app.AlturaMin = val;
                        app.SetMinButton.Enable = 'off';
                        app.SetMaxButton.Enable = 'on';
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> MÍNIMA OK (" + string(val) + "). MUEVA A MÁXIMO"];
                    else
                        uialert(app.UIFigure, "La altura Mínima no puede ser inferior al Cero.", "Error de Calibración");
                    end
        
                % 3. Recepción y Validación de MÁXIMO
                elseif startsWith(mensaje, "MAX:")
                    val = str2double(extractAfter(mensaje, "MAX:"));
                    
                    if val > app.AlturaMin
                        app.AlturaMax = val;
                        app.SetMaxButton.Enable = 'off';
                        app.SetHeigthsButton.Enable = 'on'; % Re-habilitamos por si se quiere recalibrar
                        app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> MÁXIMA OK (" + string(val) + "). ENSAYO LISTO"];
                    else
                        uialert(app.UIFigure, "La altura Máxima debe ser mayor que la Mínima.", "Error de Calibración");
                    end
                % 4. Resistencia
                elseif startsWith(mensaje, "RES: ")
                       resistencia = str2double(extractAfter(mensaje, "RES: "));
                else
                    app.MonitorTextArea.Value = [app.MonitorTextArea.Value; mensaje];
                end
                scroll(app.MonitorTextArea, 'bottom');
            catch
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.BaudRateDropDown.Value = '115200';
            % Botones de calibración apagados por defecto
            app.Set0Button.Enable = 'off';
            app.SetMinButton.Enable = 'off';
            app.SetMaxButton.Enable = 'off';

            puertos = serialportlist("available");
            app.PortDropDown.Items = puertos;
            
            % Si encuentra algún puerto, auto-selecciona el primero
            if ~isempty(puertos)
                app.PortDropDown.Value = puertos(1);
            else
                app.PortDropDown.Items = {'No detectado'};
            end
        end

        % Drop down opening function: PortDropDown
        function PortDropDownOpening(app, event)
            app.PortDropDown.Items = serialportlist("available");
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            try
                % Leemos lo que el usuario ha seleccionado en los desplegables
                app.ESP32 = serialport(app.PortDropDown.Value, str2double(app.BaudRateDropDown.Value));
                
                % MUY IMPORTANTE: Le decimos a MATLAB que nuestros mensajes terminan con un "Enter" (CR/LF)
                configureTerminator(app.ESP32, "CR/LF");

                % Le decimos: "Cada vez que veas un terminator (CR/LF), ejecuta leerMensajeSerie"
                configureCallback(app.ESP32, "terminator", @app.leerMensajeSerie);
                
                % Opcional: Cambiamos la luz a verde y el texto del botón
                app.ConnectLamp.Color = 'green';
                app.ConnectButton.Text = 'Connected';
                app.ConnectButton.Enable = 'off'; % Desactivamos el botón para no conectar 2 veces

                % Creamos un temporizador que se ejecuta cada 0.5 segundos
                % Su única función es enviar la letra 'R' al ESP32
                %app.TimerDatos = timer('ExecutionMode', 'fixedRate', 'Period', 0.5, 'TimerFcn', @(~,~) writeline(app.ESP32, "R"));
                %start(app.TimerDatos);
                
                
            catch ME
                % Si algo falla (ej. el puerto está en uso), sacamos una alerta
                uialert(app.UIFigure, "Error al conectar: " + ME.message, "Error de Conexión");
                app.ConnectLamp.Color = 'red';
                app.ConnectButton.Text = 'Error in connection';
            end
        end

        % Value changed function: ComandEditField
        function ComandEditFieldValueChanged(app, event)
            % 1. Leemos lo que has escrito y lo pasamos a mayúsculas por seguridad
            textoEscrito = upper(app.ComandEditField.Value);
            
            % 2. Verificamos que estamos conectados antes de enviar nada
            if isempty(app.ESP32) || ~isvalid(app.ESP32)
                uialert(app.UIFigure, "Conecta el puerto primero.", "Error");
                return;
            end
            
            % 3. ENVIAMOS EL COMANDO AL ESP32
            writeline(app.ESP32, textoEscrito);
            
            % 4. Mostramos en nuestro monitor lo que acabamos de enviar
            % Le pongo un "> " delante para diferenciar lo que enviamos de lo que recibimos
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> " + textoEscrito];
            scroll(app.MonitorTextArea, 'bottom');
            
            % 5. Limpiamos la barra de texto para que puedas escribir el siguiente rápido
            app.ComandEditField.Value = '';
            
        end

        % Button pushed function: UpButton
        function UpButtonPushed(app, event)
            writeline(app.ESP32,"U5");
        end

        % Button pushed function: DownButton
        function DownButtonPushed(app, event)
            writeline(app.ESP32,"D5")
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

        % Button pushed function: SetHeigthsButton
        function SetHeigthsButtonPushed(app, event)
            app.Set0Button.Enable = 'on';
            app.SetHeigthsButton.Enable = 'off'; % Se desactiva para evitar reiniciar a mitad
            
            app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> MODO CALIBRACIÓN ACTIVADO"];
        end

        % Button pushed function: Set0Button
        function Set0ButtonPushed(app, event)
            if ~isempty(app.ESP32) && isvalid(app.ESP32)
                writeline(app.ESP32, "S"); % Manda hacer cero
                app.Set0Button.Enable = 'off'; % Se deshabilita al usarse
            end
        end

        % Button pushed function: BigUpButton
        function BigUpButtonPushed(app, event)
            writeline(app.ESP32,"U50")
        end

        % Button pushed function: BigDownButton
        function BigDownButtonPushed(app, event)
            writeline(app.ESP32,"D50")
        end

        % Button pushed function: IniciarEnsayoButton
        function IniciarEnsayoButtonPushed(app, event)
            % 0. Comprobaciones iniciales
            if isempty(app.ESP32) || ~isvalid(app.ESP32)
                uialert(app.UIFigure, "Conecta el puerto primero.", "Error");
                return;
            end
            
            nCiclos = app.NCiclosEditField.Value;
            tomasPorCiclo = app.TomasPorCicloEditField.Value; % <--- NUEVO
            
            if nCiclos <= 0 || tomasPorCiclo <= 0
                return;
            end
            
            try
                % --- 1. BLOQUEAR INTERFAZ (Modo Ensayo) ---
                app.UpButton.Enable = 'off';
                app.DownButton.Enable = 'off';
                app.BigUpButton.Enable = 'off';
                app.BigDownButton.Enable = 'off';
                app.SetHeigthsButton.Enable = 'off';
                app.IniciarEnsayoButton.Enable = 'off';
                
                configureCallback(app.ESP32, "off");
                flush(app.ESP32); 
                
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> PREPARANDO: Yendo a Posición Máxima..."];
                scroll(app.MonitorTextArea, 'bottom');
                
                % --- 2. AJUSTE INICIAL ---
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
                
                distancia = app.AlturaMax - posActual;
                if distancia > 0
                    writeline(app.ESP32, "U" + string(distancia));
                elseif distancia < 0
                    writeline(app.ESP32, "D" + string(-distancia));
                end
                
                if distancia ~= 0
                    while ~startsWith(readline(app.ESP32), "MOVEMENT EXECUTED")
                    end
                end
                
                % --- 3. CÁLCULO DEL MUESTREO (Magia Matemática) ---
                amplitud = app.AlturaMax - app.AlturaMin;
                
                % Sabiendo que el motor tarda 2ms por paso:
                % Un ciclo entero (bajar y subir) tarda: amplitud * 4 milisegundos.
                % Para obtener N tomas, dividimos el tiempo total entre N.
                tiempoMuestreo_ms = round((amplitud * 4) / app.NTomascicloEditField.Value);
                
                if tiempoMuestreo_ms < 1
                    tiempoMuestreo_ms = 1; % Al menos 1ms por seguridad
                end
                
                % Le ordenamos al ESP32 que empiece a escupir datos automáticamente
                writeline(app.ESP32, "T" + string(tiempoMuestreo_ms));
                
                % Matriz dinámica para ir guardando TODO el ensayo
                datosEnsayo = []; 
                posTemp = NaN; % Variable temporal
                
                % --- 4. EJECUTAR EL BUCLE DE ENSAYO ---
                for i = 1:nCiclos
                    app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> ENSAYO: Ciclo " + string(i) + "/" + string(nCiclos)];
                    scroll(app.MonitorTextArea, 'bottom');
                    
                    % A) Bajar al Mínimo
                    writeline(app.ESP32, "D" + string(amplitud));
                    while true
                        resp = readline(app.ESP32);
                        if startsWith(resp, "MOVEMENT EXECUTED")
                            break; % Termina el movimiento
                        elseif startsWith(resp, "POS:")
                            num = regexp(resp, '-?\d+\.?\d*', 'match');
                            posTemp = str2double(num{1});
                        elseif startsWith(resp, "RES:")
                            num = regexp(resp, '-?\d+\.?\d*', 'match');
                            resTemp = str2double(num{1});
                            % Como el ESP32 envía siempre POS y justo después RES, guardamos la fila aquí
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp];
                        end
                    end
                    
                    % B) Subir al Máximo
                    writeline(app.ESP32, "U" + string(amplitud));
                    while true
                        resp = readline(app.ESP32);
                        if startsWith(resp, "MOVEMENT EXECUTED")
                            break;
                        elseif startsWith(resp, "POS:")
                            num = regexp(resp, '-?\d+\.?\d*', 'match');
                            posTemp = str2double(num{1});
                        elseif startsWith(resp, "RES:")
                            num = regexp(resp, '-?\d+\.?\d*', 'match');
                            resTemp = str2double(num{1});
                            datosEnsayo = [datosEnsayo; i, posTemp, resTemp];
                        end
                    end
                end
                
                % --- 5. PARAR MUESTREO Y GUARDAR A EXCEL ---
                writeline(app.ESP32, "T0"); % Apagamos el cronómetro del ESP32
                
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> ENSAYO COMPLETADO. Guardando datos..."];
                drawnow; % Refrescamos la pantalla
                
                % Convertimos la matriz de datos en una Tabla formal
                tablaDatos = array2table(datosEnsayo, 'VariableNames', {'Ciclo', 'Posicion', 'Resistencia'});
                
                % Generamos el nombre del archivo con la hora exacta
                % Ejemplo: "Ensayo_20231024_153045.xlsx"
                fechaStr = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
                nombreArchivo = "Ensayo_" + fechaStr + ".xlsx";
                
                % Exportamos a Excel en la misma carpeta donde esté la App
                writetable(tablaDatos, nombreArchivo);
                
                app.MonitorTextArea.Value = [app.MonitorTextArea.Value; "> Guardado con éxito en: " + nombreArchivo];
                scroll(app.MonitorTextArea, 'bottom');
                
            catch ME
                % Si hay un error de emergencia, apagamos el cronómetro para que no sature el USB
                writeline(app.ESP32, "T0");
                uialert(app.UIFigure, "Ensayo interrumpido: " + ME.message, "Aviso");
            end
            
            % --- 6. RESTAURAR LA NORMALIDAD ---
            configureCallback(app.ESP32, "terminator", @app.leerMensajeSerie);
            
            app.UpButton.Enable = 'on';
            app.DownButton.Enable = 'on';
            app.BigUpButton.Enable = 'on';
            app.BigDownButton.Enable = 'on';
            app.SetHeigthsButton.Enable = 'on';
            app.IniciarEnsayoButton.Enable = 'on';
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

            % Create IniciarEnsayoButton
            app.IniciarEnsayoButton = uibutton(app.UIFigure, 'push');
            app.IniciarEnsayoButton.ButtonPushedFcn = createCallbackFcn(app, @IniciarEnsayoButtonPushed, true);
            app.IniciarEnsayoButton.FontSize = 24;
            app.IniciarEnsayoButton.FontWeight = 'bold';
            app.IniciarEnsayoButton.Position = [700 550 200 80];
            app.IniciarEnsayoButton.Text = 'Inciar Ensayo';

            % Create NCiclosEditField
            app.NCiclosEditField = uieditfield(app.UIFigure, 'numeric');
            app.NCiclosEditField.Position = [650 450 100 20];

            % Create PortDropDown
            app.PortDropDown = uidropdown(app.UIFigure);
            app.PortDropDown.Items = {};
            app.PortDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PortDropDownOpening, true);
            app.PortDropDown.Placeholder = 'Avaliable Ports';
            app.PortDropDown.Position = [50 750 200 30];
            app.PortDropDown.Value = {};

            % Create BaudRateDropDown
            app.BaudRateDropDown = uidropdown(app.UIFigure);
            app.BaudRateDropDown.Items = {'9600', '115200', '250000'};
            app.BaudRateDropDown.Placeholder = '115200';
            app.BaudRateDropDown.Position = [320 750 100 30];
            app.BaudRateDropDown.Value = '9600';

            % Create ConnectButton
            app.ConnectButton = uibutton(app.UIFigure, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.IconAlignment = 'center';
            app.ConnectButton.FontName = 'Britannic Bold';
            app.ConnectButton.FontSize = 24;
            app.ConnectButton.FontWeight = 'bold';
            app.ConnectButton.Position = [1050 735 300 80];
            app.ConnectButton.Text = 'Connect';

            % Create ConnectLamp
            app.ConnectLamp = uilamp(app.UIFigure);
            app.ConnectLamp.Position = [1450 750 50 50];
            app.ConnectLamp.Color = [0.502 0.502 0.502];

            % Create MonitorTextArea
            app.MonitorTextArea = uitextarea(app.UIFigure);
            app.MonitorTextArea.Editable = 'off';
            app.MonitorTextArea.FontName = 'Consolas';
            app.MonitorTextArea.FontSize = 18;
            app.MonitorTextArea.FontColor = [0 1 0];
            app.MonitorTextArea.BackgroundColor = [0 0 0];
            app.MonitorTextArea.Position = [20 60 500 650];
            app.MonitorTextArea.Value = {'CONSOLE:'};

            % Create ComandEditField
            app.ComandEditField = uieditfield(app.UIFigure, 'text');
            app.ComandEditField.ValueChangedFcn = createCallbackFcn(app, @ComandEditFieldValueChanged, true);
            app.ComandEditField.Position = [20 20 500 30];

            % Create SetMaxButton
            app.SetMaxButton = uibutton(app.UIFigure, 'push');
            app.SetMaxButton.ButtonPushedFcn = createCallbackFcn(app, @SetMaxButtonPushed, true);
            app.SetMaxButton.FontSize = 18;
            app.SetMaxButton.Enable = 'off';
            app.SetMaxButton.Position = [1050 550 200 80];
            app.SetMaxButton.Text = 'SetMax';

            % Create SetMinButton
            app.SetMinButton = uibutton(app.UIFigure, 'push');
            app.SetMinButton.ButtonPushedFcn = createCallbackFcn(app, @SetMinButtonPushed, true);
            app.SetMinButton.FontSize = 18;
            app.SetMinButton.Enable = 'off';
            app.SetMinButton.Position = [1050 450 200 80];
            app.SetMinButton.Text = 'SetMin';

            % Create Set0Button
            app.Set0Button = uibutton(app.UIFigure, 'push');
            app.Set0Button.ButtonPushedFcn = createCallbackFcn(app, @Set0ButtonPushed, true);
            app.Set0Button.FontSize = 18;
            app.Set0Button.Enable = 'off';
            app.Set0Button.Position = [1050 350 200 80];
            app.Set0Button.Text = 'Set0';

            % Create UpButton
            app.UpButton = uibutton(app.UIFigure, 'push');
            app.UpButton.ButtonPushedFcn = createCallbackFcn(app, @UpButtonPushed, true);
            app.UpButton.FontSize = 18;
            app.UpButton.Position = [1310 450 80 80];
            app.UpButton.Text = '↑';

            % Create DownButton
            app.DownButton = uibutton(app.UIFigure, 'push');
            app.DownButton.ButtonPushedFcn = createCallbackFcn(app, @DownButtonPushed, true);
            app.DownButton.FontSize = 18;
            app.DownButton.Position = [1310 350 80 80];
            app.DownButton.Text = '↓';

            % Create SetHeigthsButton
            app.SetHeigthsButton = uibutton(app.UIFigure, 'push');
            app.SetHeigthsButton.ButtonPushedFcn = createCallbackFcn(app, @SetHeigthsButtonPushed, true);
            app.SetHeigthsButton.FontSize = 18;
            app.SetHeigthsButton.Position = [1300 550 200 80];
            app.SetHeigthsButton.Text = 'Set Heigths';

            % Create BigDownButton
            app.BigDownButton = uibutton(app.UIFigure, 'push');
            app.BigDownButton.ButtonPushedFcn = createCallbackFcn(app, @BigDownButtonPushed, true);
            app.BigDownButton.FontSize = 18;
            app.BigDownButton.Position = [1410 350 80 80];
            app.BigDownButton.Text = '⇓';

            % Create BigUpButton
            app.BigUpButton = uibutton(app.UIFigure, 'push');
            app.BigUpButton.ButtonPushedFcn = createCallbackFcn(app, @BigUpButtonPushed, true);
            app.BigUpButton.FontSize = 18;
            app.BigUpButton.Position = [1410 450 80 80];
            app.BigUpButton.Text = '⇑';

            % Create NCiclosLabel
            app.NCiclosLabel = uilabel(app.UIFigure);
            app.NCiclosLabel.HorizontalAlignment = 'center';
            app.NCiclosLabel.Position = [669 483 60 20];
            app.NCiclosLabel.Text = 'Nº Ciclos';

            % Create NTomascicloEditFieldLabel
            app.NTomascicloEditFieldLabel = uilabel(app.UIFigure);
            app.NTomascicloEditFieldLabel.HorizontalAlignment = 'center';
            app.NTomascicloEditFieldLabel.Position = [845 481 84 22];
            app.NTomascicloEditFieldLabel.Text = 'Nº Tomas/ciclo';

            % Create NTomascicloEditField
            app.NTomascicloEditField = uieditfield(app.UIFigure, 'numeric');
            app.NTomascicloEditField.Position = [838 450 100 20];

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