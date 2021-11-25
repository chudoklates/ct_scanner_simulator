classdef tomogramPreviewApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        atXYLabel                     matlab.ui.control.Label
        ResetwindowButton             matlab.ui.control.Button
        ReconstructionerrorEditField  matlab.ui.control.NumericEditField
        ReconstructionerrorEditFieldLabel  matlab.ui.control.Label
        ARCHIVEButton                 matlab.ui.control.Button
        WindowcenterEditField         matlab.ui.control.NumericEditField
        WindowcenterEditFieldLabel    matlab.ui.control.Label
        MinvalueEditField             matlab.ui.control.NumericEditField
        MinvalueEditFieldLabel        matlab.ui.control.Label
        MaxvalueEditField             matlab.ui.control.NumericEditField
        MaxvalueEditFieldLabel        matlab.ui.control.Label
        WindowsizeEditField           matlab.ui.control.NumericEditField
        WindowsizeEditFieldLabel      matlab.ui.control.Label
        WindowcenterSlider            matlab.ui.control.Slider
        WindowcenterSliderLabel       matlab.ui.control.Label
        DifferenceAxes                matlab.ui.control.UIAxes
        PhantomAxes                   matlab.ui.control.UIAxes
        HistogramAxes                 matlab.ui.control.UIAxes
        TomogramAxes                  matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        Parent % Parent window
        T % Tomogram
        delta = 0.000001; % Safety limit for sliders
        accuracy % Comparison score between reconstruction 
                    % and phantom
        maxV % Max allowed value
        minV % Min allowed value
    end
    
    methods (Access = private)
        
        function updateimage(app,im)
            app.T = im;
            
            % Set limits and values for threshold sliders
            maxValue = max(im, [], 'all');
            minValue = min(im, [], 'all');
            
            app.maxV = maxValue;
            app.minV = minValue;

            if(minValue == maxValue)
                % 0 case, don't display windowing
                app.WindowcenterSlider.Visible = 'off';
                app.WindowcenterSliderLabel.Visible = 'off';
                app.WindowcenterEditField.Visible = 'off';
                app.WindowcenterEditFieldLabel.Visible = 'off';
                app.WindowsizeEditField.Visible = 'off';
                app.WindowsizeEditFieldLabel.Visible = 'off';
            else
                app.WindowcenterSlider.Limits = [minValue + app.delta 
                    maxValue - app.delta];
                
                resetWindowValues(app, im)
            end
            
            
            % Display the image
            imshow(im, [], 'Parent', app.TomogramAxes)%, 'DisplayRange', ...
%                 [0, 1])
            
            colorbar(app.TomogramAxes)
                    
            % Plot all histograms with the same data for grayscale
            histb = histogram(app.HistogramAxes, im, 'EdgeColor', 'none');
        
            % Get largest bin count
            maxb = max(histb.BinCounts);
            maxcount = maxb;
            
            % Set y axes limits based on largest bin count
            app.HistogramAxes.YLim = [0 maxcount];
            app.HistogramAxes.YTick = round([0 maxcount/2 maxcount], 2, ...
                'significant');
            
            app.WindowcenterSlider.MajorTicks = app.HistogramAxes.XTick;
        end
        
        
        function updateWindow(app, im, minValue, maxValue)
            im(im < minValue) = 0;
            im(im > maxValue) = 0;
            
            imshow(im, [], 'Parent', app.TomogramAxes)%, 'DisplayRange', ...
%                 [0, 1])
        end
        
        function resetWindowValues(app, im)
            maxValue = max(im, [], 'all');
            minValue = min(im, [], 'all');
            
            windowsize = double(maxValue - minValue);
            center = double((minValue + maxValue) / 2);
            
            app.WindowsizeEditField.Value = windowsize;
            
            app.MaxvalueEditField.Value = double(maxValue);
            app.MinvalueEditField.Value = double(minValue);
            
            app.WindowcenterEditField.Value = center;
            app.WindowcenterSlider.Value = center;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, Parent, T, P)
            app.Parent = Parent;
            
            % Configure image axes
            app.TomogramAxes.Visible = 'off';
            app.TomogramAxes.Colormap = gray(256);
            axis(app.TomogramAxes, 'image');
            
            [app.accuracy, D] = ...
                computeAccuracyScore(P, T);
            
%             app.atXYLabel.Text = "at (" + int2str(x) + ", " + ...
%                 int2str(y) + ")";
            
            app.ReconstructionerrorEditField.Value = double( ...
                app.accuracy * 100); % Convert to percent
            
            imshow(D, 'Parent', app.DifferenceAxes, ...
                'DisplayRange', [0, 1])
            axis(app.DifferenceAxes, 'image');
            app.DifferenceAxes.Colormap = hot(256);
            
            imshow(P, 'Parent', app.PhantomAxes, 'DisplayRange', ...
                [0, 1])
            axis(app.PhantomAxes, 'image');
            
            % Update the image and histograms
            updateimage(app, T);
        end

        % Callback function
        function DropDownValueChanged(app, event)
           
        end

        % Callback function
        function LoadButtonPushed(app, event)
              
        end

        % Value changing function: WindowcenterSlider
        function WindowcenterSliderValueChanging(app, event)
            changingValue = event.Value;
            
            app.WindowcenterEditField.Value = changingValue;
            windowsize = app.WindowsizeEditField.Value;
            
            d = windowsize / 2;
            
            newMax = min(app.maxV, changingValue + d);
            newMin = max(app.minV, changingValue - d);
            
            app.MaxvalueEditField.Value = newMax;
            app.MinvalueEditField.Value = newMin;
            
            updateWindow(app, app.T, newMin, newMax)
        end

        % Callback function
        function MaxSliderValueChanging(app, event)
%             changingValue = event.Value;
%             
%             if app.WindowcenterSlider.Value >= changingValue
%                 app.WindowcenterSlider.Value = changingValue - app.delta;
%             end
%             
%             updateWindow(app, app.T, app.WindowcenterSlider.Value, changingValue)
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            app.Parent.TomogramPreviewDialog = 0;
            
            delete(app)
        end

        % Button down function: HistogramAxes
        function HistogramAxesButtonDown(app, event)
            openHistogram(app.T)
        end

        % Value changed function: WindowsizeEditField
        function WindowsizeEditFieldValueChanged(app, event)
            windowsize = app.WindowsizeEditField.Value;
            
            newSize = min(app.maxV - app.minV, windowsize);
            app.WindowsizeEditField.Value = newSize;
            
            center = app.WindowcenterSlider.Value;
            
            d = newSize / 2;
            
            newMax = min(app.maxV, center + d);
            newMin = max(app.minV, center - d);
            
            app.MaxvalueEditField.Value = newMax;
            app.MinvalueEditField.Value = newMin;
            
            updateWindow(app, app.T, newMin, newMax)
        end

        % Value changed function: MaxvalueEditField
        function MaxvalueEditFieldValueChanged(app, event)
            value = app.MaxvalueEditField.Value;
            minValue = app.MinvalueEditField.Value;
            
            newMax = max(minValue + 1, ...
                min(app.maxV, value));
            app.MaxvalueEditField.Value = newMax;
            
            newSize = newMax - minValue;
            app.WindowsizeEditField.Value = newSize;
            
            newCenter = (minValue + newMax) / 2;
            app.WindowcenterSlider.Value = newCenter;
            app.WindowcenterEditField.Value = newCenter;
            
            updateWindow(app, app.T, minValue, newMax)
        end

        % Value changed function: MinvalueEditField
        function MinvalueEditFieldValueChanged(app, event)
            value = app.MinvalueEditField.Value;
            maxValue = app.MaxvalueEditField.Value;
            
            newMin = min(max(app.minV, value), ...
                maxValue - 1);
            app.MinvalueEditField.Value = newMin;
            
            newSize = maxValue - newMin;
            app.WindowsizeEditField.Value = newSize;
            
            newCenter = (newMin + maxValue) / 2;
            app.WindowcenterSlider.Value = newCenter;
            app.WindowcenterEditField.Value = newCenter;
            
            updateWindow(app, app.T, newMin, maxValue)
        end

        % Value changed function: WindowcenterEditField
        function WindowcenterEditFieldValueChanged(app, event)
            value = app.WindowcenterEditField.Value;
            
            windowsize = app.WindowsizeEditField.Value;
            
            d = windowsize / 2;
            
            newMax = min(app.maxV, value + d);
            newMin = max(app.minV, value - d);
            
            app.MaxvalueEditField.Value = newMax;
            app.MinvalueEditField.Value = newMin;
            
            updateWindow(app, app.T, newMin, newMax)
        end

        % Button pushed function: ResetwindowButton
        function ResetwindowButtonPushed(app, event)
            resetWindowValues(app, app.T);
            
            updateWindow(app, app.T, app.minV, app.maxV)
        end

        % Button pushed function: ARCHIVEButton
        function ARCHIVEButtonPushed(app, event)
            [file, path, ix] = uiputfile({'*.csv';'*.png';'*.jpg';'*.tiff'});
            
            filename = fullfile(path, file);
            
            if ix == 1
                writematrix(app.T, filename)
            else
                imwrite(app.T, filename)
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
            app.UIFigure.Position = [100 100 1229 618];
            app.UIFigure.Name = 'Tomogram Details';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create TomogramAxes
            app.TomogramAxes = uiaxes(app.UIFigure);
            title(app.TomogramAxes, 'Tomogram')
            zlabel(app.TomogramAxes, 'Z')
            app.TomogramAxes.Toolbar.Visible = 'off';
            app.TomogramAxes.Position = [322 6 535 601];

            % Create HistogramAxes
            app.HistogramAxes = uiaxes(app.UIFigure);
            title(app.HistogramAxes, 'Histogram')
            xlabel(app.HistogramAxes, 'Values')
            ylabel(app.HistogramAxes, 'Pixels')
            zlabel(app.HistogramAxes, 'Z')
            subtitle(app.HistogramAxes, 'Click to open in new window')
            app.HistogramAxes.ButtonDownFcn = createCallbackFcn(app, @HistogramAxesButtonDown, true);
            app.HistogramAxes.Position = [866 364 336 155];

            % Create PhantomAxes
            app.PhantomAxes = uiaxes(app.UIFigure);
            title(app.PhantomAxes, 'Original phantom')
            zlabel(app.PhantomAxes, 'Z')
            app.PhantomAxes.Toolbar.Visible = 'off';
            app.PhantomAxes.Position = [16 308 290 299];

            % Create DifferenceAxes
            app.DifferenceAxes = uiaxes(app.UIFigure);
            title(app.DifferenceAxes, 'Difference map')
            zlabel(app.DifferenceAxes, 'Z')
            app.DifferenceAxes.Toolbar.Visible = 'off';
            app.DifferenceAxes.Position = [16 6 290 298];

            % Create WindowcenterSliderLabel
            app.WindowcenterSliderLabel = uilabel(app.UIFigure);
            app.WindowcenterSliderLabel.HorizontalAlignment = 'center';
            app.WindowcenterSliderLabel.Position = [1003 315 86 22];
            app.WindowcenterSliderLabel.Text = 'Window center';

            % Create WindowcenterSlider
            app.WindowcenterSlider = uislider(app.UIFigure);
            app.WindowcenterSlider.ValueChangingFcn = createCallbackFcn(app, @WindowcenterSliderValueChanging, true);
            app.WindowcenterSlider.MinorTicks = [];
            app.WindowcenterSlider.Tooltip = {'Use this slider to move the center of the thresholding window'};
            app.WindowcenterSlider.Position = [921 298 268 3];

            % Create WindowsizeEditFieldLabel
            app.WindowsizeEditFieldLabel = uilabel(app.UIFigure);
            app.WindowsizeEditFieldLabel.HorizontalAlignment = 'center';
            app.WindowsizeEditFieldLabel.Position = [1062 192 73 22];
            app.WindowsizeEditFieldLabel.Text = 'Window size';

            % Create WindowsizeEditField
            app.WindowsizeEditField = uieditfield(app.UIFigure, 'numeric');
            app.WindowsizeEditField.Limits = [0.0001 Inf];
            app.WindowsizeEditField.ValueChangedFcn = createCallbackFcn(app, @WindowsizeEditFieldValueChanged, true);
            app.WindowsizeEditField.Tooltip = {'Increase/decrease the size of the thresholding window. Size in this context is the amplitude between min and max accepted value.'};
            app.WindowsizeEditField.Position = [1146 192 56 22];
            app.WindowsizeEditField.Value = 1;

            % Create MaxvalueEditFieldLabel
            app.MaxvalueEditFieldLabel = uilabel(app.UIFigure);
            app.MaxvalueEditFieldLabel.HorizontalAlignment = 'center';
            app.MaxvalueEditFieldLabel.Position = [921 149 60 22];
            app.MaxvalueEditFieldLabel.Text = 'Max value';

            % Create MaxvalueEditField
            app.MaxvalueEditField = uieditfield(app.UIFigure, 'numeric');
            app.MaxvalueEditField.ValueChangedFcn = createCallbackFcn(app, @MaxvalueEditFieldValueChanged, true);
            app.MaxvalueEditField.Tooltip = {'Maximal coefficient value accepted by the thresholding window'};
            app.MaxvalueEditField.Position = [996 149 56 22];

            % Create MinvalueEditFieldLabel
            app.MinvalueEditFieldLabel = uilabel(app.UIFigure);
            app.MinvalueEditFieldLabel.HorizontalAlignment = 'center';
            app.MinvalueEditFieldLabel.Position = [1078 149 57 22];
            app.MinvalueEditFieldLabel.Text = 'Min value';

            % Create MinvalueEditField
            app.MinvalueEditField = uieditfield(app.UIFigure, 'numeric');
            app.MinvalueEditField.ValueChangedFcn = createCallbackFcn(app, @MinvalueEditFieldValueChanged, true);
            app.MinvalueEditField.Tooltip = {'Minimal coefficient value accepted by the thresholding window'};
            app.MinvalueEditField.Position = [1147 149 56 22];

            % Create WindowcenterEditFieldLabel
            app.WindowcenterEditFieldLabel = uilabel(app.UIFigure);
            app.WindowcenterEditFieldLabel.HorizontalAlignment = 'center';
            app.WindowcenterEditFieldLabel.Position = [895 192 86 22];
            app.WindowcenterEditFieldLabel.Text = 'Window center';

            % Create WindowcenterEditField
            app.WindowcenterEditField = uieditfield(app.UIFigure, 'numeric');
            app.WindowcenterEditField.ValueChangedFcn = createCallbackFcn(app, @WindowcenterEditFieldValueChanged, true);
            app.WindowcenterEditField.Tooltip = {'If you would like to enter a precise value for the center of the window, use this input'};
            app.WindowcenterEditField.Position = [996 192 56 22];

            % Create ARCHIVEButton
            app.ARCHIVEButton = uibutton(app.UIFigure, 'push');
            app.ARCHIVEButton.ButtonPushedFcn = createCallbackFcn(app, @ARCHIVEButtonPushed, true);
            app.ARCHIVEButton.BackgroundColor = [0.302 0.7451 0.9333];
            app.ARCHIVEButton.FontSize = 18;
            app.ARCHIVEButton.FontWeight = 'bold';
            app.ARCHIVEButton.FontColor = [1 1 1];
            app.ARCHIVEButton.Position = [906 34 292 38];
            app.ARCHIVEButton.Text = 'ARCHIVE';

            % Create ReconstructionerrorEditFieldLabel
            app.ReconstructionerrorEditFieldLabel = uilabel(app.UIFigure);
            app.ReconstructionerrorEditFieldLabel.HorizontalAlignment = 'center';
            app.ReconstructionerrorEditFieldLabel.FontWeight = 'bold';
            app.ReconstructionerrorEditFieldLabel.Position = [894 557 125 22];
            app.ReconstructionerrorEditFieldLabel.Text = 'Reconstruction error';

            % Create ReconstructionerrorEditField
            app.ReconstructionerrorEditField = uieditfield(app.UIFigure, 'numeric');
            app.ReconstructionerrorEditField.ValueDisplayFormat = '%11.4g%%';
            app.ReconstructionerrorEditField.Tooltip = {'Difference between original and reconstructed phantom, expressed as ratio of sum of differences over sum of all pixels in the original phantom.'};
            app.ReconstructionerrorEditField.Position = [1098 557 100 22];

            % Create ResetwindowButton
            app.ResetwindowButton = uibutton(app.UIFigure, 'push');
            app.ResetwindowButton.ButtonPushedFcn = createCallbackFcn(app, @ResetwindowButtonPushed, true);
            app.ResetwindowButton.VerticalAlignment = 'top';
            app.ResetwindowButton.BackgroundColor = [0.5686 0.8784 1];
            app.ResetwindowButton.FontSize = 16;
            app.ResetwindowButton.FontColor = [1 1 1];
            app.ResetwindowButton.Position = [906 98 292 30];
            app.ResetwindowButton.Text = 'Reset window';

            % Create atXYLabel
            app.atXYLabel = uilabel(app.UIFigure);
            app.atXYLabel.HorizontalAlignment = 'right';
            app.atXYLabel.Visible = 'off';
            app.atXYLabel.Position = [1097 536 101 22];
            app.atXYLabel.Text = 'at (X, Y)';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = tomogramPreviewApp(varargin)

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