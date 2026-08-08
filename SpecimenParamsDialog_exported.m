classdef SpecimenParamsDialog_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        CancelButton                   matlab.ui.control.Button
        TabGroup                       matlab.ui.container.TabGroup
        TestTab                        matlab.ui.container.Tab
        ConsecutiveTestsEditField      matlab.ui.control.NumericEditField
        ConsecutiveTestsEditField_2Label  matlab.ui.control.Label
        AcceptButton                   matlab.ui.control.Button
        NFilterIntervalEditField       matlab.ui.control.NumericEditField
        NFilterIntervalEditFieldLabel  matlab.ui.control.Label
        ExcelCheckBox                  matlab.ui.control.CheckBox
        RepetitionsEditField           matlab.ui.control.NumericEditField
        RepetitionsEditFieldLabel      matlab.ui.control.Label
        LengthcmDropDown               matlab.ui.control.DropDown
        LengthcmDropDownLabel          matlab.ui.control.Label
        ThicknesscmEditField           matlab.ui.control.NumericEditField
        ThicknesscmEditFieldLabel      matlab.ui.control.Label
        WidthcmEditField               matlab.ui.control.NumericEditField
        WidthcmEditFieldLabel          matlab.ui.control.Label
        InfillDropDown                 matlab.ui.control.DropDown
        InfillLabel                    matlab.ui.control.Label
        SpecimenNameEditField          matlab.ui.control.EditField
        SpecimenNameEditFieldLabel     matlab.ui.control.Label
        SpecimenParamsDialogLabel      matlab.ui.control.Label
        ResistanceTab                  matlab.ui.container.Tab
        AcceptButton_r                 matlab.ui.control.Button
        NFilterIntervalEditField_r     matlab.ui.control.NumericEditField
        NFilterIntervalEditField_2Label  matlab.ui.control.Label
        InfillDropDown_r               matlab.ui.control.DropDown
        InfillDropDown_2Label          matlab.ui.control.Label
        LengthcmDropDown_r             matlab.ui.control.DropDown
        LengthcmDropDown_2Label        matlab.ui.control.Label
        ThicknesscmEditField_r         matlab.ui.control.NumericEditField
        ThicknesscmEditField_2Label    matlab.ui.control.Label
        WidthcmEditField_r             matlab.ui.control.NumericEditField
        WidthcmEditField_2Label        matlab.ui.control.Label
        SpecimenNameEditField_r        matlab.ui.control.EditField
        SpecimenNameEditField_2Label   matlab.ui.control.Label
        ExcelCheckBox_r                matlab.ui.control.CheckBox
        SpecimenParamsDialogLabel_r    matlab.ui.control.Label
    end

    
    properties (Access = public)
        SpecimenName string = ""
        TotalTests double = 1
        Length_cm double = 10
        Width_cm double = 1
        Thickness_cm double = 0.2
        Infill string = ""
        GenerateExcel logical = true
        FilterInterval double = 30
        Cycles double = 20
        IsCanceled logical = true
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: AcceptButton
        function AcceptButtonPushed(app, event)

            % 1. Guardamos los valores
            app.SpecimenName = app.SpecimenNameEditField.Value;
            app.Infill = app.InfillDropDown.Value;
            app.GenerateExcel = app.ExcelCheckBox.Value;
            app.FilterInterval = app.NFilterIntervalEditField.Value;
            app.TotalTests = app.ConsecutiveTestsEditField.Value;
            app.Cycles = app.RepetitionsEditField.Value;
            app.Width_cm = app.WidthcmEditField.Value;
            app.Thickness_cm = app.ThicknesscmEditField.Value;
            app.Length_cm = str2double(app.LengthcmDropDown.Value);
            app.Cycles = app.RepetitionsEditField.Value;

            
            % 2. Marcamos que NO se ha cancelado, ocultamos la ventana y reanudamos
            app.IsCanceled = false;
            app.UIFigure.Visible = 'off';
            uiresume(app.UIFigure);

        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            app.IsCanceled = true;
            app.UIFigure.Visible = 'off';
            uiresume(app.UIFigure);
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.IsCanceled = true;
            app.UIFigure.Visible = 'off';
            uiresume(app.UIFigure);
        end

        % Button pushed function: AcceptButton_r
        function AcceptButton_rPushed(app, event)
            
            % 1. Guardamos los valores
            app.SpecimenName = app.SpecimenNameEditField_r.Value;
            app.Infill = app.InfillDropDown_r.Value;
            app.GenerateExcel = app.ExcelCheckBox_r.Value;
            app.FilterInterval = app.NFilterIntervalEditField_r.Value;
            app.Width_cm = app.WidthcmEditField_r.Value;
            app.Thickness_cm = app.ThicknesscmEditField_r.Value;
            app.Length_cm = str2double(app.LengthcmDropDown_r.Value);

            % 2. Marcamos que NO se ha cancelado, ocultamos la ventana y reanudamos
            app.IsCanceled = false;
            app.UIFigure.Visible = 'off';
            uiresume(app.UIFigure);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'Test Parameters Input';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 640 503];

            % Create TestTab
            app.TestTab = uitab(app.TabGroup);
            app.TestTab.Title = 'Test';

            % Create SpecimenParamsDialogLabel
            app.SpecimenParamsDialogLabel = uilabel(app.TestTab);
            app.SpecimenParamsDialogLabel.HorizontalAlignment = 'center';
            app.SpecimenParamsDialogLabel.FontName = 'Artifakt Element Black';
            app.SpecimenParamsDialogLabel.FontSize = 24;
            app.SpecimenParamsDialogLabel.FontWeight = 'bold';
            app.SpecimenParamsDialogLabel.Position = [144 400 350 50];
            app.SpecimenParamsDialogLabel.Text = 'SpecimenParamsDialog';

            % Create SpecimenNameEditFieldLabel
            app.SpecimenNameEditFieldLabel = uilabel(app.TestTab);
            app.SpecimenNameEditFieldLabel.HorizontalAlignment = 'center';
            app.SpecimenNameEditFieldLabel.Position = [70 345 120 25];
            app.SpecimenNameEditFieldLabel.Text = 'Specimen Name:';

            % Create SpecimenNameEditField
            app.SpecimenNameEditField = uieditfield(app.TestTab, 'text');
            app.SpecimenNameEditField.Position = [70 310 120 25];

            % Create InfillLabel
            app.InfillLabel = uilabel(app.TestTab);
            app.InfillLabel.HorizontalAlignment = 'center';
            app.InfillLabel.Position = [260 245 120 25];
            app.InfillLabel.Text = 'Infill :';

            % Create InfillDropDown
            app.InfillDropDown = uidropdown(app.TestTab);
            app.InfillDropDown.Items = {'Giroid (G)', 'Aligned Rectilinear (r)', 'Concentrical (C)', 'Cubic (+)', 'Full (F)'};
            app.InfillDropDown.Position = [260 210 120 25];
            app.InfillDropDown.Value = 'Giroid (G)';

            % Create WidthcmEditFieldLabel
            app.WidthcmEditFieldLabel = uilabel(app.TestTab);
            app.WidthcmEditFieldLabel.HorizontalAlignment = 'center';
            app.WidthcmEditFieldLabel.Position = [450 345 120 25];
            app.WidthcmEditFieldLabel.Text = 'Width (cm):';

            % Create WidthcmEditField
            app.WidthcmEditField = uieditfield(app.TestTab, 'numeric');
            app.WidthcmEditField.HorizontalAlignment = 'center';
            app.WidthcmEditField.Position = [450 310 120 25];
            app.WidthcmEditField.Value = 1;

            % Create ThicknesscmEditFieldLabel
            app.ThicknesscmEditFieldLabel = uilabel(app.TestTab);
            app.ThicknesscmEditFieldLabel.HorizontalAlignment = 'center';
            app.ThicknesscmEditFieldLabel.Position = [450 245 120 25];
            app.ThicknesscmEditFieldLabel.Text = 'Thickness (cm):';

            % Create ThicknesscmEditField
            app.ThicknesscmEditField = uieditfield(app.TestTab, 'numeric');
            app.ThicknesscmEditField.HorizontalAlignment = 'center';
            app.ThicknesscmEditField.Position = [450 210 120 25];
            app.ThicknesscmEditField.Value = 0.2;

            % Create LengthcmDropDownLabel
            app.LengthcmDropDownLabel = uilabel(app.TestTab);
            app.LengthcmDropDownLabel.HorizontalAlignment = 'center';
            app.LengthcmDropDownLabel.Position = [270 345 100 25];
            app.LengthcmDropDownLabel.Text = 'Length (cm):';

            % Create LengthcmDropDown
            app.LengthcmDropDown = uidropdown(app.TestTab);
            app.LengthcmDropDown.Items = {'5', '10', '15'};
            app.LengthcmDropDown.Position = [270 310 100 25];
            app.LengthcmDropDown.Value = '10';

            % Create RepetitionsEditFieldLabel
            app.RepetitionsEditFieldLabel = uilabel(app.TestTab);
            app.RepetitionsEditFieldLabel.HorizontalAlignment = 'center';
            app.RepetitionsEditFieldLabel.Position = [368 155 120 25];
            app.RepetitionsEditFieldLabel.Text = 'Repetitions:';

            % Create RepetitionsEditField
            app.RepetitionsEditField = uieditfield(app.TestTab, 'numeric');
            app.RepetitionsEditField.HorizontalAlignment = 'center';
            app.RepetitionsEditField.Position = [368 120 120 25];

            % Create ExcelCheckBox
            app.ExcelCheckBox = uicheckbox(app.TestTab);
            app.ExcelCheckBox.Text = 'Excel';
            app.ExcelCheckBox.Position = [541 407 51 22];
            app.ExcelCheckBox.Value = true;

            % Create NFilterIntervalEditFieldLabel
            app.NFilterIntervalEditFieldLabel = uilabel(app.TestTab);
            app.NFilterIntervalEditFieldLabel.HorizontalAlignment = 'center';
            app.NFilterIntervalEditFieldLabel.Position = [70 245 120 25];
            app.NFilterIntervalEditFieldLabel.Text = 'N Filter Interval';

            % Create NFilterIntervalEditField
            app.NFilterIntervalEditField = uieditfield(app.TestTab, 'numeric');
            app.NFilterIntervalEditField.HorizontalAlignment = 'center';
            app.NFilterIntervalEditField.Position = [70 210 120 25];
            app.NFilterIntervalEditField.Value = 30;

            % Create AcceptButton
            app.AcceptButton = uibutton(app.TestTab, 'push');
            app.AcceptButton.ButtonPushedFcn = createCallbackFcn(app, @AcceptButtonPushed, true);
            app.AcceptButton.BackgroundColor = [0.6 0.8392 0.5882];
            app.AcceptButton.FontSize = 18;
            app.AcceptButton.Position = [135 50 150 50];
            app.AcceptButton.Text = 'Accept';

            % Create ConsecutiveTestsEditField_2Label
            app.ConsecutiveTestsEditField_2Label = uilabel(app.TestTab);
            app.ConsecutiveTestsEditField_2Label.HorizontalAlignment = 'center';
            app.ConsecutiveTestsEditField_2Label.Position = [150 155 120 25];
            app.ConsecutiveTestsEditField_2Label.Text = 'Consecutive Tests:';

            % Create ConsecutiveTestsEditField
            app.ConsecutiveTestsEditField = uieditfield(app.TestTab, 'numeric');
            app.ConsecutiveTestsEditField.HorizontalAlignment = 'center';
            app.ConsecutiveTestsEditField.Position = [150 120 120 25];
            app.ConsecutiveTestsEditField.Value = 1;

            % Create ResistanceTab
            app.ResistanceTab = uitab(app.TabGroup);
            app.ResistanceTab.Title = 'Resistance';

            % Create SpecimenParamsDialogLabel_r
            app.SpecimenParamsDialogLabel_r = uilabel(app.ResistanceTab);
            app.SpecimenParamsDialogLabel_r.HorizontalAlignment = 'center';
            app.SpecimenParamsDialogLabel_r.FontName = 'Artifakt Element Black';
            app.SpecimenParamsDialogLabel_r.FontSize = 24;
            app.SpecimenParamsDialogLabel_r.FontWeight = 'bold';
            app.SpecimenParamsDialogLabel_r.Position = [144 400 350 50];
            app.SpecimenParamsDialogLabel_r.Text = 'SpecimenParamsDialog';

            % Create ExcelCheckBox_r
            app.ExcelCheckBox_r = uicheckbox(app.ResistanceTab);
            app.ExcelCheckBox_r.Text = 'Excel';
            app.ExcelCheckBox_r.Position = [541 407 51 22];
            app.ExcelCheckBox_r.Value = true;

            % Create SpecimenNameEditField_2Label
            app.SpecimenNameEditField_2Label = uilabel(app.ResistanceTab);
            app.SpecimenNameEditField_2Label.HorizontalAlignment = 'center';
            app.SpecimenNameEditField_2Label.Position = [70 345 120 25];
            app.SpecimenNameEditField_2Label.Text = 'Specimen Name:';

            % Create SpecimenNameEditField_r
            app.SpecimenNameEditField_r = uieditfield(app.ResistanceTab, 'text');
            app.SpecimenNameEditField_r.Position = [70 310 120 25];

            % Create WidthcmEditField_2Label
            app.WidthcmEditField_2Label = uilabel(app.ResistanceTab);
            app.WidthcmEditField_2Label.HorizontalAlignment = 'center';
            app.WidthcmEditField_2Label.Position = [450 345 120 25];
            app.WidthcmEditField_2Label.Text = 'Width (cm):';

            % Create WidthcmEditField_r
            app.WidthcmEditField_r = uieditfield(app.ResistanceTab, 'numeric');
            app.WidthcmEditField_r.HorizontalAlignment = 'center';
            app.WidthcmEditField_r.Position = [450 310 120 25];
            app.WidthcmEditField_r.Value = 1;

            % Create ThicknesscmEditField_2Label
            app.ThicknesscmEditField_2Label = uilabel(app.ResistanceTab);
            app.ThicknesscmEditField_2Label.HorizontalAlignment = 'center';
            app.ThicknesscmEditField_2Label.Position = [450 245 120 25];
            app.ThicknesscmEditField_2Label.Text = 'Thickness (cm):';

            % Create ThicknesscmEditField_r
            app.ThicknesscmEditField_r = uieditfield(app.ResistanceTab, 'numeric');
            app.ThicknesscmEditField_r.HorizontalAlignment = 'center';
            app.ThicknesscmEditField_r.Position = [450 210 120 25];
            app.ThicknesscmEditField_r.Value = 0.2;

            % Create LengthcmDropDown_2Label
            app.LengthcmDropDown_2Label = uilabel(app.ResistanceTab);
            app.LengthcmDropDown_2Label.HorizontalAlignment = 'center';
            app.LengthcmDropDown_2Label.Position = [259 345 120 25];
            app.LengthcmDropDown_2Label.Text = 'Length (cm):';

            % Create LengthcmDropDown_r
            app.LengthcmDropDown_r = uidropdown(app.ResistanceTab);
            app.LengthcmDropDown_r.Items = {'5', '10', '15'};
            app.LengthcmDropDown_r.Position = [259 310 120 25];
            app.LengthcmDropDown_r.Value = '10';

            % Create InfillDropDown_2Label
            app.InfillDropDown_2Label = uilabel(app.ResistanceTab);
            app.InfillDropDown_2Label.HorizontalAlignment = 'center';
            app.InfillDropDown_2Label.Position = [244 245 150 25];
            app.InfillDropDown_2Label.Text = 'Infill :';

            % Create InfillDropDown_r
            app.InfillDropDown_r = uidropdown(app.ResistanceTab);
            app.InfillDropDown_r.Items = {'Giroid (G)', 'Aligned Rectilinear (r)', 'Concentrical (C)', 'Cubic (+)'};
            app.InfillDropDown_r.Position = [244 210 150 25];
            app.InfillDropDown_r.Value = 'Aligned Rectilinear (r)';

            % Create NFilterIntervalEditField_2Label
            app.NFilterIntervalEditField_2Label = uilabel(app.ResistanceTab);
            app.NFilterIntervalEditField_2Label.HorizontalAlignment = 'center';
            app.NFilterIntervalEditField_2Label.Position = [70 245 120 25];
            app.NFilterIntervalEditField_2Label.Text = 'N Filter Interval';

            % Create NFilterIntervalEditField_r
            app.NFilterIntervalEditField_r = uieditfield(app.ResistanceTab, 'numeric');
            app.NFilterIntervalEditField_r.HorizontalAlignment = 'center';
            app.NFilterIntervalEditField_r.Position = [70 210 120 25];
            app.NFilterIntervalEditField_r.Value = 30;

            % Create AcceptButton_r
            app.AcceptButton_r = uibutton(app.ResistanceTab, 'push');
            app.AcceptButton_r.ButtonPushedFcn = createCallbackFcn(app, @AcceptButton_rPushed, true);
            app.AcceptButton_r.FontSize = 18;
            app.AcceptButton_r.Position = [135 50 150 50];
            app.AcceptButton_r.Text = 'Accept';

            % Create CancelButton
            app.CancelButton = uibutton(app.UIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.BackgroundColor = [0.7686 0.3529 0.3529];
            app.CancelButton.FontSize = 18;
            app.CancelButton.FontColor = [0 0 0];
            app.CancelButton.Position = [360 50 150 50];
            app.CancelButton.Text = 'Cancel';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SpecimenParamsDialog_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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