classdef sinogramPreviewApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        MinvalueEditField             matlab.ui.control.NumericEditField
        MinvalueEditFieldLabel        matlab.ui.control.Label
        MaxvalueEditField             matlab.ui.control.NumericEditField
        MaxvalueEditFieldLabel        matlab.ui.control.Label
        NofraysEditField              matlab.ui.control.NumericEditField
        NofraysEditFieldLabel         matlab.ui.control.Label
        NofprojectionsEditField       matlab.ui.control.NumericEditField
        NofprojectionsEditFieldLabel  matlab.ui.control.Label
        SinogramAxes                  matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        Parent % Parent window
        S % Sinogram
    end
    
    methods (Access = private)
        
        function updateimage(app, im, Theta, xp)
            app.S = im;
            
            iptsetpref('ImshowAxesVisible','on')
            
            imshow(im,[],'Xdata',Theta,'Ydata',xp, ...
                'InitialMagnification','fit', ...
                'Parent', app.SinogramAxes)
            
            app.SinogramAxes.XLim = [min(Theta) max(Theta)];
            app.SinogramAxes.YLim = [min(xp) max(xp)];
            
            iptsetpref('ImshowAxesVisible','off')
            
            colormap(app.SinogramAxes,'hot')
            colorbar(app.SinogramAxes)
            
            [app.NofraysEditField.Value, ...
                app.NofprojectionsEditField.Value] = size(im);
            
            maxValue = max(im, [], 'all');
            minValue = min(im, [], 'all');
                       
            app.MaxvalueEditField.Value = double(maxValue);
            app.MinvalueEditField.Value = double(minValue);
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, Parent, S, Theta, xp)
            app.Parent = Parent;
            
            % Update the image and histograms
            updateimage(app, S, Theta, xp);
        end

        % Callback function
        function DropDownValueChanged(app, event)
           
        end

        % Callback function
        function LoadButtonPushed(app, event)
              
        end

        % Callback function
        function MinSliderValueChanging(app, event)
   
        end

        % Callback function
        function MaxSliderValueChanging(app, event)

        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.Parent.SinogramPreviewDialog = 0;
            
            delete(app)
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 647 443];
            app.UIFigure.Name = 'Sinogram Details';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create SinogramAxes
            app.SinogramAxes = uiaxes(app.UIFigure);
            title(app.SinogramAxes, 'Sinogram')
            xlabel(app.SinogramAxes, '\theta (degrees)')
            ylabel(app.SinogramAxes, 'x''')
            zlabel(app.SinogramAxes, 'Z')
            app.SinogramAxes.Color = [0 0 0];
            app.SinogramAxes.Position = [1 1 419 443];

            % Create NofprojectionsEditFieldLabel
            app.NofprojectionsEditFieldLabel = uilabel(app.UIFigure);
            app.NofprojectionsEditFieldLabel.Position = [434 281 91 22];
            app.NofprojectionsEditFieldLabel.Text = 'N of projections';

            % Create NofprojectionsEditField
            app.NofprojectionsEditField = uieditfield(app.UIFigure, 'numeric');
            app.NofprojectionsEditField.Editable = 'off';
            app.NofprojectionsEditField.Position = [549 281 76 22];

            % Create NofraysEditFieldLabel
            app.NofraysEditFieldLabel = uilabel(app.UIFigure);
            app.NofraysEditFieldLabel.Position = [434 240 54 22];
            app.NofraysEditFieldLabel.Text = 'N of rays';

            % Create NofraysEditField
            app.NofraysEditField = uieditfield(app.UIFigure, 'numeric');
            app.NofraysEditField.Editable = 'off';
            app.NofraysEditField.Position = [549 240 75 22];

            % Create MaxvalueEditFieldLabel
            app.MaxvalueEditFieldLabel = uilabel(app.UIFigure);
            app.MaxvalueEditFieldLabel.Position = [434 196 60 22];
            app.MaxvalueEditFieldLabel.Text = 'Max value';

            % Create MaxvalueEditField
            app.MaxvalueEditField = uieditfield(app.UIFigure, 'numeric');
            app.MaxvalueEditField.Editable = 'off';
            app.MaxvalueEditField.Position = [549 196 74 22];

            % Create MinvalueEditFieldLabel
            app.MinvalueEditFieldLabel = uilabel(app.UIFigure);
            app.MinvalueEditFieldLabel.Position = [434 155 57 22];
            app.MinvalueEditFieldLabel.Text = 'Min value';

            % Create MinvalueEditField
            app.MinvalueEditField = uieditfield(app.UIFigure, 'numeric');
            app.MinvalueEditField.Editable = 'off';
            app.MinvalueEditField.Position = [549 155 73 22];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = sinogramPreviewApp(varargin)

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