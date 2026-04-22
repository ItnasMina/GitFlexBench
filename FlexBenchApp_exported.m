classdef FlexBenchApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        TabGroup               matlab.ui.container.TabGroup
        MainTab                matlab.ui.container.Tab
        ConfiguracinTab        matlab.ui.container.Tab
        BigUpButton            matlab.ui.control.Button
        BigDownButton          matlab.ui.control.Button
        SetHeigthsButton       matlab.ui.control.Button
        DownButton             matlab.ui.control.Button
        UpButton               matlab.ui.control.Button
        Set0Button             matlab.ui.control.Button
        SetMinButton           matlab.ui.control.Button
        SetMaxButton           matlab.ui.control.Button
        ComandEditField        matlab.ui.control.EditField
        ComandEditFieldLabel   matlab.ui.control.Label
        MonitorTextArea        matlab.ui.control.TextArea
        ConnectLamp            matlab.ui.control.Lamp
        ConnectButton          matlab.ui.control.Button
        BaudRateDropDown       matlab.ui.control.DropDown
        BaudRateDropDownLabel  matlab.ui.control.Label
        PortDropDown           matlab.ui.control.DropDown
        PortDropDownLabel      matlab.ui.control.Label
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
                    
                    if val >= app.AlturaCero
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

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.AutoResizeChildren = 'off';
            app.TabGroup.Position = [0 1 1540 845];

            % Create MainTab
            app.MainTab = uitab(app.TabGroup);
            app.MainTab.AutoResizeChildren = 'off';
            app.MainTab.Title = 'Main';

            % Create ConfiguracinTab
            app.ConfiguracinTab = uitab(app.TabGroup);
            app.ConfiguracinTab.AutoResizeChildren = 'off';
            app.ConfiguracinTab.Title = 'Configuración';
            app.ConfiguracinTab.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ConfiguracinTab.ForegroundColor = [0 0 0];

            % Create PortDropDownLabel
            app.PortDropDownLabel = uilabel(app.ConfiguracinTab);
            app.PortDropDownLabel.HorizontalAlignment = 'right';
            app.PortDropDownLabel.FontWeight = 'bold';
            app.PortDropDownLabel.Position = [217 748 29 22];
            app.PortDropDownLabel.Text = 'Port';

            % Create PortDropDown
            app.PortDropDown = uidropdown(app.ConfiguracinTab);
            app.PortDropDown.Items = {};
            app.PortDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PortDropDownOpening, true);
            app.PortDropDown.Placeholder = 'Avaliable Ports';
            app.PortDropDown.Position = [261 748 182 22];
            app.PortDropDown.Value = {};

            % Create BaudRateDropDownLabel
            app.BaudRateDropDownLabel = uilabel(app.ConfiguracinTab);
            app.BaudRateDropDownLabel.HorizontalAlignment = 'right';
            app.BaudRateDropDownLabel.Position = [570 740 62 30];
            app.BaudRateDropDownLabel.Text = 'Baud Rate';

            % Create BaudRateDropDown
            app.BaudRateDropDown = uidropdown(app.ConfiguracinTab);
            app.BaudRateDropDown.Items = {'9600', '115200', '250000'};
            app.BaudRateDropDown.Placeholder = '115200';
            app.BaudRateDropDown.Position = [647 740 100 30];
            app.BaudRateDropDown.Value = '9600';

            % Create ConnectButton
            app.ConnectButton = uibutton(app.ConfiguracinTab, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.IconAlignment = 'center';
            app.ConnectButton.FontName = 'Britannic Bold';
            app.ConnectButton.FontSize = 24;
            app.ConnectButton.FontWeight = 'bold';
            app.ConnectButton.Position = [1200 724 220 82];
            app.ConnectButton.Text = 'Connect';

            % Create ConnectLamp
            app.ConnectLamp = uilamp(app.ConfiguracinTab);
            app.ConnectLamp.Position = [1469 747 45 45];
            app.ConnectLamp.Color = [0.502 0.502 0.502];

            % Create MonitorTextArea
            app.MonitorTextArea = uitextarea(app.ConfiguracinTab);
            app.MonitorTextArea.Editable = 'off';
            app.MonitorTextArea.FontName = 'Consolas';
            app.MonitorTextArea.FontSize = 18;
            app.MonitorTextArea.FontColor = [0 1 0];
            app.MonitorTextArea.BackgroundColor = [0 0 0];
            app.MonitorTextArea.Position = [148 128 483 567];
            app.MonitorTextArea.Value = {'CONSOLE:'};

            % Create ComandEditFieldLabel
            app.ComandEditFieldLabel = uilabel(app.ConfiguracinTab);
            app.ComandEditFieldLabel.HorizontalAlignment = 'right';
            app.ComandEditFieldLabel.Position = [83 87 50 22];
            app.ComandEditFieldLabel.Text = 'Comand';

            % Create ComandEditField
            app.ComandEditField = uieditfield(app.ConfiguracinTab, 'text');
            app.ComandEditField.ValueChangedFcn = createCallbackFcn(app, @ComandEditFieldValueChanged, true);
            app.ComandEditField.Position = [148 81 483 32];

            % Create SetMaxButton
            app.SetMaxButton = uibutton(app.ConfiguracinTab, 'push');
            app.SetMaxButton.ButtonPushedFcn = createCallbackFcn(app, @SetMaxButtonPushed, true);
            app.SetMaxButton.FontSize = 18;
            app.SetMaxButton.Enable = 'off';
            app.SetMaxButton.Position = [1000 450 200 80];
            app.SetMaxButton.Text = 'SetMax';

            % Create SetMinButton
            app.SetMinButton = uibutton(app.ConfiguracinTab, 'push');
            app.SetMinButton.ButtonPushedFcn = createCallbackFcn(app, @SetMinButtonPushed, true);
            app.SetMinButton.FontSize = 18;
            app.SetMinButton.Enable = 'off';
            app.SetMinButton.Position = [1000 350 200 80];
            app.SetMinButton.Text = 'SetMin';

            % Create Set0Button
            app.Set0Button = uibutton(app.ConfiguracinTab, 'push');
            app.Set0Button.ButtonPushedFcn = createCallbackFcn(app, @Set0ButtonPushed, true);
            app.Set0Button.FontSize = 18;
            app.Set0Button.Enable = 'off';
            app.Set0Button.Position = [1000 250 200 80];
            app.Set0Button.Text = 'Set0';

            % Create UpButton
            app.UpButton = uibutton(app.ConfiguracinTab, 'push');
            app.UpButton.ButtonPushedFcn = createCallbackFcn(app, @UpButtonPushed, true);
            app.UpButton.FontSize = 18;
            app.UpButton.Position = [1260 350 80 80];
            app.UpButton.Text = '↑';

            % Create DownButton
            app.DownButton = uibutton(app.ConfiguracinTab, 'push');
            app.DownButton.ButtonPushedFcn = createCallbackFcn(app, @DownButtonPushed, true);
            app.DownButton.FontSize = 18;
            app.DownButton.Position = [1260 250 80 80];
            app.DownButton.Text = '↓';

            % Create SetHeigthsButton
            app.SetHeigthsButton = uibutton(app.ConfiguracinTab, 'push');
            app.SetHeigthsButton.ButtonPushedFcn = createCallbackFcn(app, @SetHeigthsButtonPushed, true);
            app.SetHeigthsButton.FontSize = 18;
            app.SetHeigthsButton.Position = [1250 450 200 80];
            app.SetHeigthsButton.Text = 'Set Heigths';

            % Create BigDownButton
            app.BigDownButton = uibutton(app.ConfiguracinTab, 'push');
            app.BigDownButton.ButtonPushedFcn = createCallbackFcn(app, @BigDownButtonPushed, true);
            app.BigDownButton.FontSize = 18;
            app.BigDownButton.Position = [1360 250 80 80];
            app.BigDownButton.Text = '⇓';

            % Create BigUpButton
            app.BigUpButton = uibutton(app.ConfiguracinTab, 'push');
            app.BigUpButton.ButtonPushedFcn = createCallbackFcn(app, @BigUpButtonPushed, true);
            app.BigUpButton.FontSize = 18;
            app.BigUpButton.Position = [1360 350 80 80];
            app.BigUpButton.Text = '⇑';

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