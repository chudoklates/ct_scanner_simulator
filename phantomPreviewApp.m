classdef phantomPreviewApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        EditingLamp                   matlab.ui.control.Lamp
        EditingLampLabel              matlab.ui.control.Label
        SAVEButton                    matlab.ui.control.Button
        EdittoolsPanel                matlab.ui.container.Panel
        BrushtypeDropDown             matlab.ui.control.DropDown
        BrushtypeDropDownLabel        matlab.ui.control.Label
        BrushthicknessEditField       matlab.ui.control.NumericEditField
        BrushthicknessEditFieldLabel  matlab.ui.control.Label
        AttenuationcoefficientEditField  matlab.ui.control.NumericEditField
        AttenuationcoefficientEditFieldLabel  matlab.ui.control.Label
        ModeSwitch                    matlab.ui.control.ToggleSwitch
        ModeSwitchLabel               matlab.ui.control.Label
        MinvalueEditField             matlab.ui.control.NumericEditField
        MinvalueEditFieldLabel        matlab.ui.control.Label
        MaxvalueEditField             matlab.ui.control.NumericEditField
        MaxvalueEditFieldLabel        matlab.ui.control.Label
        HeightEditField               matlab.ui.control.NumericEditField
        HeightEditFieldLabel          matlab.ui.control.Label
        WidthEditField                matlab.ui.control.NumericEditField
        WidthEditFieldLabel           matlab.ui.control.Label
        HistogramAxes                 matlab.ui.control.UIAxes
        ImageAxes                     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        Parent % Parent window
        P % Phantom object
        Edit % Edit mode
    end
    
    methods (Access = private)
        
        function updateimage(app,im)
            app.P = im;
            
            I = imshow(im, [], 'Parent', app.ImageAxes, ...
                'DisplayRange', [0, 1]);
            
            I.HitTest = 'off';
            set(app.ImageAxes, 'PickableParts', 'all')
            
            colorbar(app.ImageAxes)
                    
            % Plot all histograms with the same data for grayscale
            histb = histogram(app.HistogramAxes, im, ...
                'EdgeColor', 'none');
        
            % Get largest bin count
            maxb = max(histb.BinCounts);
            maxcount = maxb;
            
            % Set y axes limits based on largest bin count
            app.HistogramAxes.YLim = [0 maxcount];
            app.HistogramAxes.YTick = round( ...
                [0 maxcount/2 maxcount], 2, 'significant');
            
            [app.WidthEditField.Value, ...
                app.HeightEditField.Value] = size(im);
            
            maxValue = max(im, [], 'all');
            minValue = min(im, [], 'all');
                       
            app.MaxvalueEditField.Value = double(maxValue);
            app.MinvalueEditField.Value = double(minValue);
        end
        
        function imageDrawHandler(app, x, y)
            im = app.P;
            
            thickness = floor(app.BrushthicknessEditField.Value / 2);
            
            [maxX, ...
                maxY] = size(im);
            
            xcoordinates = ...
                max(x-thickness, 1):min(x+thickness, maxX);
            
            ycoordinates = ...
                max(y-thickness, 1):min(y+thickness, maxY);
            
            im(xcoordinates,ycoordinates) = double( ...
                app.AttenuationcoefficientEditField.Value);
            
            updateimage(app, im)
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, P, Parent)
            % Configure image axes
%             app.ImageAxes.Visible = 'off';
            app.ImageAxes.Colormap = gray(256);
%             app.ImageAxes.Interactions = [];
            axis(app.ImageAxes, 'image');
            
            app.Parent = Parent;
            
            % Update the image and histograms
            updateimage(app, P);
        end

        % Callback function
        function DropDownValueChanged(app, event)
           
        end

        % Callback function
        function LoadButtonPushed(app, event)
              
        end

        % Button down function: ImageAxes
        function ImageAxesButtonDown(app, event)
            if event.Button == 1 % Left Mouse button
                i = event.IntersectionPoint;
                
                x = round(i(2));
                y = round(i(1));
                
                if app.Edit
                    imageDrawHandler(app, x, y);
                else
                    app.AttenuationcoefficientEditField.Value ...
                        = double(app.P(x, y));
                end
                
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.Parent.PhantomPreviewDialog = 0;
            
            delete(app)
        end

        % Value changed function: ModeSwitch
        function ModeSwitchValueChanged(app, event)
            value = app.ModeSwitch.Value;
            
            on = value == 'edit';
            if on
                enable = 'on';
            else
                enable = 'off';
            end
            
            app.Edit = on;
            app.AttenuationcoefficientEditField.Editable = enable;
            app.EdittoolsPanel.Enable = enable;
            app.EditingLamp.Enable = enable;
        end

        % Button pushed function: SAVEButton
        function SAVEButtonPushed(app, event)
            app.Parent.P = app.P;
            
            app.Parent.updateImage(app.P);
        end

        % Button down function: HistogramAxes
        function HistogramAxesButtonDown(app, event)
            openHistogram(app.P)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 833 518];
            app.UIFigure.Name = 'Phantom Details';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create ImageAxes
            app.ImageAxes = uiaxes(app.UIFigure);
            title(app.ImageAxes, 'Phantom')
            xlabel(app.ImageAxes, 'X')
            ylabel(app.ImageAxes, 'Y')
            zlabel(app.ImageAxes, 'Z')
            app.ImageAxes.Layer = 'top';
            app.ImageAxes.MinorGridLineStyle = '-';
            app.ImageAxes.ButtonDownFcn = createCallbackFcn(app, @ImageAxesButtonDown, true);
            app.ImageAxes.Position = [1 1 490 505];

            % Create HistogramAxes
            app.HistogramAxes = uiaxes(app.UIFigure);
            title(app.HistogramAxes, 'Histogram')
            xlabel(app.HistogramAxes, 'Values')
            ylabel(app.HistogramAxes, 'Pixels')
            zlabel(app.HistogramAxes, 'Z')
            subtitle(app.HistogramAxes, 'Click to open in new window')
            app.HistogramAxes.ButtonDownFcn = createCallbackFcn(app, @HistogramAxesButtonDown, true);
            app.HistogramAxes.Position = [504 146 317 141];

            % Create WidthEditFieldLabel
            app.WidthEditFieldLabel = uilabel(app.UIFigure);
            app.WidthEditFieldLabel.Position = [536 111 37 22];
            app.WidthEditFieldLabel.Text = 'Width';

            % Create WidthEditField
            app.WidthEditField = uieditfield(app.UIFigure, 'numeric');
            app.WidthEditField.Editable = 'off';
            app.WidthEditField.Position = [602 111 54 22];

            % Create HeightEditFieldLabel
            app.HeightEditFieldLabel = uilabel(app.UIFigure);
            app.HeightEditFieldLabel.Position = [695 111 41 22];
            app.HeightEditFieldLabel.Text = 'Height';

            % Create HeightEditField
            app.HeightEditField = uieditfield(app.UIFigure, 'numeric');
            app.HeightEditField.Editable = 'off';
            app.HeightEditField.Position = [761 111 53 22];

            % Create MaxvalueEditFieldLabel
            app.MaxvalueEditFieldLabel = uilabel(app.UIFigure);
            app.MaxvalueEditFieldLabel.Position = [531 70 60 22];
            app.MaxvalueEditFieldLabel.Text = 'Max value';

            % Create MaxvalueEditField
            app.MaxvalueEditField = uieditfield(app.UIFigure, 'numeric');
            app.MaxvalueEditField.Editable = 'off';
            app.MaxvalueEditField.Position = [601 70 55 22];

            % Create MinvalueEditFieldLabel
            app.MinvalueEditFieldLabel = uilabel(app.UIFigure);
            app.MinvalueEditFieldLabel.Position = [689 70 57 22];
            app.MinvalueEditFieldLabel.Text = 'Min value';

            % Create MinvalueEditField
            app.MinvalueEditField = uieditfield(app.UIFigure, 'numeric');
            app.MinvalueEditField.Editable = 'off';
            app.MinvalueEditField.Position = [759 70 54 22];

            % Create ModeSwitchLabel
            app.ModeSwitchLabel = uilabel(app.UIFigure);
            app.ModeSwitchLabel.HorizontalAlignment = 'center';
            app.ModeSwitchLabel.FontWeight = 'bold';
            app.ModeSwitchLabel.Position = [502 413 38 22];
            app.ModeSwitchLabel.Text = 'Mode';

            % Create ModeSwitch
            app.ModeSwitch = uiswitch(app.UIFigure, 'toggle');
            app.ModeSwitch.Items = {'Sample', 'Edit'};
            app.ModeSwitch.ItemsData = {'view', 'edit'};
            app.ModeSwitch.ValueChangedFcn = createCallbackFcn(app, @ModeSwitchValueChanged, true);
            app.ModeSwitch.Tooltip = {'Switch between Editing and Sampling mode. In Sampling mode (default) you can get the value of the attenuation coefficent at cursor position by clicking. With Editing mode, you can change the value of the attenuation coefficient at and around the cursor.'};
            app.ModeSwitch.Position = [511 339 20 45];
            app.ModeSwitch.Value = 'view';

            % Create AttenuationcoefficientEditFieldLabel
            app.AttenuationcoefficientEditFieldLabel = uilabel(app.UIFigure);
            app.AttenuationcoefficientEditFieldLabel.HorizontalAlignment = 'right';
            app.AttenuationcoefficientEditFieldLabel.FontWeight = 'bold';
            app.AttenuationcoefficientEditFieldLabel.Position = [573 463 135 22];
            app.AttenuationcoefficientEditFieldLabel.Text = 'Attenuation coefficient';

            % Create AttenuationcoefficientEditField
            app.AttenuationcoefficientEditField = uieditfield(app.UIFigure, 'numeric');
            app.AttenuationcoefficientEditField.Limits = [0 1];
            app.AttenuationcoefficientEditField.Editable = 'off';
            app.AttenuationcoefficientEditField.Position = [744 463 70 22];

            % Create EdittoolsPanel
            app.EdittoolsPanel = uipanel(app.UIFigure);
            app.EdittoolsPanel.AutoResizeChildren = 'off';
            app.EdittoolsPanel.Enable = 'off';
            app.EdittoolsPanel.Title = 'Edit tools';
            app.EdittoolsPanel.Position = [573 303 248 144];

            % Create BrushthicknessEditFieldLabel
            app.BrushthicknessEditFieldLabel = uilabel(app.EdittoolsPanel);
            app.BrushthicknessEditFieldLabel.HorizontalAlignment = 'right';
            app.BrushthicknessEditFieldLabel.Position = [81 61 91 22];
            app.BrushthicknessEditFieldLabel.Text = 'Brush thickness';

            % Create BrushthicknessEditField
            app.BrushthicknessEditField = uieditfield(app.EdittoolsPanel, 'numeric');
            app.BrushthicknessEditField.Limits = [1 Inf];
            app.BrushthicknessEditField.RoundFractionalValues = 'on';
            app.BrushthicknessEditField.Position = [198 61 43 22];
            app.BrushthicknessEditField.Value = 1;

            % Create BrushtypeDropDownLabel
            app.BrushtypeDropDownLabel = uilabel(app.EdittoolsPanel);
            app.BrushtypeDropDownLabel.HorizontalAlignment = 'right';
            app.BrushtypeDropDownLabel.Position = [63 92 64 22];
            app.BrushtypeDropDownLabel.Text = 'Brush type';

            % Create BrushtypeDropDown
            app.BrushtypeDropDown = uidropdown(app.EdittoolsPanel);
            app.BrushtypeDropDown.Items = {'Dot', 'Line', 'Ellipse', 'Rectangle'};
            app.BrushtypeDropDown.ItemsData = {'dot', 'line', 'ellipse', 'rectangle'};
            app.BrushtypeDropDown.Position = [142 92 100 22];
            app.BrushtypeDropDown.Value = 'dot';

            % Create SAVEButton
            app.SAVEButton = uibutton(app.UIFigure, 'push');
            app.SAVEButton.ButtonPushedFcn = createCallbackFcn(app, @SAVEButtonPushed, true);
            app.SAVEButton.BackgroundColor = [0.302 0.7451 0.9333];
            app.SAVEButton.FontSize = 18;
            app.SAVEButton.FontWeight = 'bold';
            app.SAVEButton.FontColor = [1 1 1];
            app.SAVEButton.Position = [521 16 292 38];
            app.SAVEButton.Text = 'SAVE';

            % Create EditingLampLabel
            app.EditingLampLabel = uilabel(app.UIFigure);
            app.EditingLampLabel.HorizontalAlignment = 'center';
            app.EditingLampLabel.FontWeight = 'bold';
            app.EditingLampLabel.Position = [500 464 45 22];
            app.EditingLampLabel.Text = 'Editing';

            % Create EditingLamp
            app.EditingLamp = uilamp(app.UIFigure);
            app.EditingLamp.Enable = 'off';
            app.EditingLamp.Position = [512 446 20 20];
            app.EditingLamp.Color = [1 0.851 0.3098];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = phantomPreviewApp(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

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