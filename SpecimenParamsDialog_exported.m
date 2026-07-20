classdef SpecimenParamsDialog_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TestParametersInputUIFigure     matlab.ui.Figure
        InfillDropDown                  matlab.ui.control.DropDown
        InfillLabel                     matlab.ui.control.Label
        LengthcmDropDown                matlab.ui.control.DropDown
        LengthcmDropDownLabel           matlab.ui.control.Label
        ThicknesscmEditField            matlab.ui.control.NumericEditField
        ThicknesscmEditFieldLabel       matlab.ui.control.Label
        WidthcmEditField                matlab.ui.control.NumericEditField
        WidthcmEditFieldLabel           matlab.ui.control.Label
        ConsecutiveTestsEditField       matlab.ui.control.NumericEditField
        ConsecutiveTestsEditFieldLabel  matlab.ui.control.Label
        SpecimenNameEditField           matlab.ui.control.EditField
        SpecimenNameEditFieldLabel      matlab.ui.control.Label
        CancelButton                    matlab.ui.control.Button
        AcceptButton                    matlab.ui.control.Button
        SpecimenParamsDialogLabel       matlab.ui.control.Label
    end

    
    properties (Access = public)
        SpecimenName string = ""
        TotalTests double = 1
        Length_cm double = 10
        Width_cm double = 1
        Thickness_cm double = 0.2
        Infill double = 10 
        IsCanceled logical = true % Flag de seguridad inicializado en true
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: AcceptButton
        function AcceptButtonPushed(app, event)

            % 1. Guardamos el texto directo
            app.SpecimenName = app.SpecimenNameEditField.Value;
            
            % 2. Guardamos los números directos
            app.TotalTests = app.ConsecutiveTestsEditField.Value;
            app.Width_cm = app.WidthcmEditField.Value;
            app.Thickness_cm = app.ThicknesscmEditField.Value;
            
            % 3. Convertimos el texto de los DropDown a números
            app.Length_cm = str2double(app.LengthcmDropDown.Value);
            app.Infill = str2double(app.InfillDropDown.Value);
            
            % 4. Marcamos que NO se ha cancelado, ocultamos la ventana y reanudamos
            app.IsCanceled = false;
            app.TestParametersInputUIFigure.Visible = 'off';
            uiresume(app.TestParametersInputUIFigure);

        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            app.IsCanceled = true;
            app.TestParametersInputUIFigure.Visible = 'off';
            uiresume(app.TestParametersInputUIFigure);
        end

        % Close request function: TestParametersInputUIFigure
        function UIFigureCloseRequest(app, event)
            app.IsCanceled = true;
            app.TestParametersInputUIFigure.Visible = 'off';
            uiresume(app.TestParametersInputUIFigure);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create TestParametersInputUIFigure and hide until all components are created
            app.TestParametersInputUIFigure = uifigure('Visible', 'off');
            app.TestParametersInputUIFigure.Position = [100 100 640 480];
            app.TestParametersInputUIFigure.Name = 'Test Parameters Input';
            app.TestParametersInputUIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create SpecimenParamsDialogLabel
            app.SpecimenParamsDialogLabel = uilabel(app.TestParametersInputUIFigure);
            app.SpecimenParamsDialogLabel.HorizontalAlignment = 'center';
            app.SpecimenParamsDialogLabel.FontName = 'Artifakt Element Black';
            app.SpecimenParamsDialogLabel.FontSize = 24;
            app.SpecimenParamsDialogLabel.FontWeight = 'bold';
            app.SpecimenParamsDialogLabel.Position = [170 400 300 50];
            app.SpecimenParamsDialogLabel.Text = 'SpecimenParamsDialog';

            % Create AcceptButton
            app.AcceptButton = uibutton(app.TestParametersInputUIFigure, 'push');
            app.AcceptButton.ButtonPushedFcn = createCallbackFcn(app, @AcceptButtonPushed, true);
            app.AcceptButton.FontSize = 18;
            app.AcceptButton.Position = [130 100 150 40];
            app.AcceptButton.Text = 'Accept';

            % Create CancelButton
            app.CancelButton = uibutton(app.TestParametersInputUIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.FontSize = 18;
            app.CancelButton.Position = [360 100 150 40];
            app.CancelButton.Text = 'Cancel';

            % Create SpecimenNameEditFieldLabel
            app.SpecimenNameEditFieldLabel = uilabel(app.TestParametersInputUIFigure);
            app.SpecimenNameEditFieldLabel.HorizontalAlignment = 'center';
            app.SpecimenNameEditFieldLabel.Position = [70 335 120 25];
            app.SpecimenNameEditFieldLabel.Text = 'Specimen Name:';

            % Create SpecimenNameEditField
            app.SpecimenNameEditField = uieditfield(app.TestParametersInputUIFigure, 'text');
            app.SpecimenNameEditField.Position = [70 300 120 25];

            % Create ConsecutiveTestsEditFieldLabel
            app.ConsecutiveTestsEditFieldLabel = uilabel(app.TestParametersInputUIFigure);
            app.ConsecutiveTestsEditFieldLabel.HorizontalAlignment = 'center';
            app.ConsecutiveTestsEditFieldLabel.Position = [70 235 120 25];
            app.ConsecutiveTestsEditFieldLabel.Text = 'Consecutive Tests:';

            % Create ConsecutiveTestsEditField
            app.ConsecutiveTestsEditField = uieditfield(app.TestParametersInputUIFigure, 'numeric');
            app.ConsecutiveTestsEditField.HorizontalAlignment = 'center';
            app.ConsecutiveTestsEditField.Position = [70 200 120 25];

            % Create WidthcmEditFieldLabel
            app.WidthcmEditFieldLabel = uilabel(app.TestParametersInputUIFigure);
            app.WidthcmEditFieldLabel.HorizontalAlignment = 'center';
            app.WidthcmEditFieldLabel.Position = [450 335 120 25];
            app.WidthcmEditFieldLabel.Text = 'Width (cm):';

            % Create WidthcmEditField
            app.WidthcmEditField = uieditfield(app.TestParametersInputUIFigure, 'numeric');
            app.WidthcmEditField.HorizontalAlignment = 'center';
            app.WidthcmEditField.Position = [450 300 120 25];
            app.WidthcmEditField.Value = 1;

            % Create ThicknesscmEditFieldLabel
            app.ThicknesscmEditFieldLabel = uilabel(app.TestParametersInputUIFigure);
            app.ThicknesscmEditFieldLabel.HorizontalAlignment = 'center';
            app.ThicknesscmEditFieldLabel.Position = [450 235 120 25];
            app.ThicknesscmEditFieldLabel.Text = 'Thickness (cm):';

            % Create ThicknesscmEditField
            app.ThicknesscmEditField = uieditfield(app.TestParametersInputUIFigure, 'numeric');
            app.ThicknesscmEditField.HorizontalAlignment = 'center';
            app.ThicknesscmEditField.Position = [450 200 120 25];
            app.ThicknesscmEditField.Value = 0.2;

            % Create LengthcmDropDownLabel
            app.LengthcmDropDownLabel = uilabel(app.TestParametersInputUIFigure);
            app.LengthcmDropDownLabel.HorizontalAlignment = 'center';
            app.LengthcmDropDownLabel.Position = [260 235 120 25];
            app.LengthcmDropDownLabel.Text = 'Length (cm):';

            % Create LengthcmDropDown
            app.LengthcmDropDown = uidropdown(app.TestParametersInputUIFigure);
            app.LengthcmDropDown.Items = {'5', '10', '15'};
            app.LengthcmDropDown.Position = [260 200 120 25];
            app.LengthcmDropDown.Value = '10';

            % Create InfillLabel
            app.InfillLabel = uilabel(app.TestParametersInputUIFigure);
            app.InfillLabel.HorizontalAlignment = 'center';
            app.InfillLabel.Position = [260 335 120 25];
            app.InfillLabel.Text = 'Infill :';

            % Create InfillDropDown
            app.InfillDropDown = uidropdown(app.TestParametersInputUIFigure);
            app.InfillDropDown.Items = {'5', '10', '15'};
            app.InfillDropDown.Position = [260 300 120 25];
            app.InfillDropDown.Value = '10';

            % Show the figure after all components are created
            app.TestParametersInputUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SpecimenParamsDialog_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.TestParametersInputUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TestParametersInputUIFigure)
        end
    end
end