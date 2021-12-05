classdef main < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        CTScannerSimulatorUIFigure    matlab.ui.Figure
        TomogramPanel                 matlab.ui.container.Panel
        InverseRadonTransformLabel    matlab.ui.control.Label
        ReconstructionalgorithmLabel  matlab.ui.control.Label
        FiltertypeDropDown            matlab.ui.control.DropDown
        FiltertypeDropDownLabel       matlab.ui.control.Label
        InterpolationDropDown         matlab.ui.control.DropDown
        InterpolationDropDownLabel    matlab.ui.control.Label
        TomogramDetailsButton         matlab.ui.control.Button
        RECONSTRUCTButton             matlab.ui.control.Button
        TomogramAxes                  matlab.ui.control.UIAxes
        SinogramPanel                 matlab.ui.container.Panel
        RadonTransformLabel           matlab.ui.control.Label
        ScanningalgorithmLabel        matlab.ui.control.Label
        VarianceEditField             matlab.ui.control.NumericEditField
        VarianceEditFieldLabel        matlab.ui.control.Label
        MeanEditField                 matlab.ui.control.NumericEditField
        MeanEditFieldLabel            matlab.ui.control.Label
        AddGaussiannoiseCheckBox      matlab.ui.control.CheckBox
        AutoCheckBox                  matlab.ui.control.CheckBox
        SinogramDetailsButton         matlab.ui.control.Button
        NofraysEditField              matlab.ui.control.NumericEditField
        NofraysEditFieldLabel         matlab.ui.control.Label
        ThetastepEditField            matlab.ui.control.NumericEditField
        ThetastepEditFieldLabel       matlab.ui.control.Label
        ThetamaxEditField             matlab.ui.control.NumericEditField
        ThetamaxEditFieldLabel        matlab.ui.control.Label
        ThetaminEditField             matlab.ui.control.NumericEditField
        ThetaminEditFieldLabel        matlab.ui.control.Label
        SCANButton                    matlab.ui.control.Button
        SinogramAxes                  matlab.ui.control.UIAxes
        PhantomPanel                  matlab.ui.container.Panel
        PhantomDescription            matlab.ui.control.TextArea
        ChangeButton                  matlab.ui.control.Button
        ImagenameLabel                matlab.ui.control.Label
        PhantomDetailsButton          matlab.ui.control.Button
        TypeofphantomDropDown         matlab.ui.control.DropDown
        TypeofphantomDropDownLabel    matlab.ui.control.Label
        ImageAxes                     matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        P = phantom(256) % Scanned object
        PhantomPreviewDialog % Phantom preview sub-app
        TomogramPreviewDialog % Tomogram preview sub-app
        SinogramPreviewDialog % Sinogram preview sub-app
    end
    
    properties (Access = private)
        S % Sinogram of the scanned object
        T % Tomogram of the scanned object
        D_Theta % D_Theta for computing reverse transform
        NRays = 367 % N of rays for Radon projection
        RadCor % Coordinates for Sinogram
        Th % Theta value
    end
    
    methods (Access = private)
        
%         function N = computeDefaultNRays(~, im)
%             N = 2*ceil(norm(size(im)- ...
%                     floor((size(im)-1)/2)-1))+3;
%         end
        
        function showHideImageLabel(app, show, filename)
            if (show)
                visible = 'on';
            else
                visible = 'off';
            end
            
            app.ImagenameLabel.Visible = visible;
            
            if(filename)
                app.ImagenameLabel.Text = filename;
            end
            
            app.ChangeButton.Visible = visible;
        end
        
        function uploadImageFile(app)
            [file, path] = uigetfile({'*.png';'*.jpg';'*.tiff'});
            
            if(file)
                filename = fullfile(path, file);
            
                % Convert image to greyscale
                I = im2gray(imread(filename));
                % Ensure matching type for phantom (most images are 
                % imported as uint8
                I = double(I);
                % Normalize image data to [0, 1]
                I = I / 255;
                app.P = I;
                % Show image label with name of file
                showHideImageLabel(app, true, file)
            end
        end
        
        function closeDialog(~, dialog)
            if(isobject(dialog))
                delete(dialog)
            end
        end
        
        function closeAllDialogs(app)
            closeDialog(app, app.PhantomPreviewDialog)
            closeDialog(app, app.SinogramPreviewDialog)
            closeDialog(app, app.TomogramPreviewDialog)
        end
        
        function setDescription(app, type)
            description = '';
            
            switch(type)
                case 'shepp-logan'
                    description = ...
                        ['Model of a human head; Standard test ' ...
                        'image used in development of image ' ...
                        'reconstruction algorithms'];
                case 'checkerboard'
                    description = ...
                        '20x20 black, white & grey checkerboard';
                case 'empty'
                    description = ...
                        'Empty image for editing';
                case 'custom'
                    description = ...
                        'Upload custom image';
            end
            
            app.PhantomDescription.Value = description;
        end
    end
    
    methods (Access = public)
        function updateImage(app, im)
            % Autoupdate N of rays if auto is selected
            if app.AutoCheckBox.Value
                nOfRays = computeDefaultNRays(im);
                app.NofraysEditField.Value = nOfRays;
                app.NRays = nOfRays;
            end
            
            % Display image in preview
            imshow(im, 'Parent', app.ImageAxes, ...
                'DisplayRange', [0, 1])
%             imagesc(app.ImageAxes, im)
%             app.Image.ImageSource = repmat(im, 1, 1, 3);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.ImageAxes.Visible = 'off';
            app.ImageAxes.Colormap = gray(256);
            app.TomogramAxes.Colormap = gray(256);
            axis(app.ImageAxes, 'image');
            
            updateImage(app, app.P)
        end

        % Value changed function: TypeofphantomDropDown
        function TypeofphantomDropDownValueChanged(app, event)
            value = app.TypeofphantomDropDown.Value;
            
            % Close preview dialog if it's opened
            closeDialog(app, app.PhantomPreviewDialog)
            
            switch(value)
                case 'shepp-logan'
                    app.P = phantom(256);
                    
                    showHideImageLabel(app, false, '')
                case 'checkerboard'
                    app.P = checkerboard(20);
                        
                    showHideImageLabel(app, false, '')
                case 'empty'
                    app.P = zeros(256);
                        
                    showHideImageLabel(app, false, '')
                case 'custom'
                    uploadImageFile(app)
            end
                    
            setDescription(app, value)
            
            updateImage(app, app.P)
        end

        % Button pushed function: SCANButton
        function SCANButtonPushed(app, event)
            % Update the clicked button to reflect loading state
            app.SCANButton.Enable = 'off';
            app.SCANButton.Text = 'SCANNING...';
            
            % Re-draw GUI on demand
            drawnow;
            
            % Collect data from inputs
            thetaMin = app.ThetaminEditField.Value;
            thetaMax = app.ThetamaxEditField.Value;
            thetaStep = app.ThetastepEditField.Value;
            
            Theta = thetaMin:thetaStep:thetaMax;
            
            % Perform Radon transformation of the phantom
            [R, xp] = radon(app.P, Theta, app.NRays);
            
            sin = R;
            
            % Add noise if desired
            if app.AddGaussiannoiseCheckBox.Value
                m = app.MeanEditField.Value;
                var = app.VarianceEditField.Value;
                
                maxSin = max(sin, [], 'all');
                minSin = min(sin, [], 'all');
                
                amplitude = maxSin - minSin;
                
                noise = double( ...
                    ((m / 100) * amplitude) + ...
                    (randn(size(sin)) * ...
                    sqrt((var / 100) * amplitude)) ...
                    );
                
                sin = sin + noise;
            end
            
            % Save result and parameters for later reference
            app.S = sin;
            app.D_Theta = thetaStep;
            app.RadCor = xp;
            app.Th = Theta;
            
            % Display results
            iptsetpref('ImshowAxesVisible','on')
            
            imshow(sin,[],'Xdata',Theta,'Ydata',xp, ...
                'InitialMagnification','fit', ...
                'Parent', app.SinogramAxes)
            
            app.SinogramAxes.XLim = [thetaMin thetaMax];
            app.SinogramAxes.YLim = [min(xp) max(xp)];
            
            colormap(app.SinogramAxes,'hot')
            colorbar(app.SinogramAxes)
            
            iptsetpref('ImshowAxesVisible','off')
            
            app.TomogramPanel.Enable = 'on';
            app.SinogramDetailsButton.Enable = 'on';
            
            app.SCANButton.Enable = 'on';
            app.SCANButton.Text = 'SCAN';
        end

        % Button pushed function: RECONSTRUCTButton
        function RECONSTRUCTButtonPushed(app, event)
            % Update the clicked button to reflect loading state
            app.RECONSTRUCTButton.Enable = 'off';
            app.RECONSTRUCTButton.Text = 'RECONSTRUCTING...';
            
            % Re-draw GUI on demand
            drawnow;
            
            % Collect data from inputs
            filter = app.FiltertypeDropDown.Value;
            interpolation = app.InterpolationDropDown.Value;
            
            sin = app.S;
            
            % Perform reconstruction
            I = iradon(sin,app.D_Theta, interpolation, filter, ...
                 1, max(size(app.P)));
            
            % Display results
            iptsetpref('ImshowAxesVisible','off')
            
            imshow(I, [], 'Parent', app.TomogramAxes)%, ...
%                 'DisplayRange', [0, 1])
            axis(app.TomogramAxes, 'image');
            
            % Save tomogram
            app.T = I;
            
            % Enable tomogram preview
            app.TomogramDetailsButton.Enable = 'on';
            
            % Update button again to finish loading state
            app.RECONSTRUCTButton.Enable = 'on';
            app.RECONSTRUCTButton.Text = 'RECONSTRUCT';
        end

        % Value changed function: AddGaussiannoiseCheckBox
        function AddGaussiannoiseCheckBoxValueChanged(app, event)
            value = app.AddGaussiannoiseCheckBox.Value;
            
            enable = 'off';
            
            if(value)
                enable = 'on';
            end
            
%             app.NoisetypeDropDownLabel.Enable = enable;
            app.MeanEditFieldLabel.Enable = enable;
            app.VarianceEditFieldLabel.Enable = enable;
            
%             app.NoisetypeDropDown.Enable = enable;
            app.MeanEditField.Enable = enable;
            app.VarianceEditField.Enable = enable;
        end

        % Button pushed function: PhantomDetailsButton
        function PhantomDetailsButtonPushed(app, event)
            app.PhantomPreviewDialog = ...
                phantomPreviewApp(app.P, app);
        end

        % Button pushed function: TomogramDetailsButton
        function TomogramDetailsButtonPushed(app, event)
            app.TomogramPreviewDialog = ...
                tomogramPreviewApp(app, app.T, app.P);
        end

        % Value changed function: NofraysEditField
        function NofraysEditFieldValueChanged(app, event)
            value = app.NofraysEditField.Value;
            
            app.NRays = value;
        end

        % Value changed function: AutoCheckBox
        function AutoCheckBoxValueChanged(app, event)
            value = app.AutoCheckBox.Value;
            
            if value
                app.NofraysEditField.Enable = 'off';
                app.NofraysEditFieldLabel.Enable = 'off';
                nOfRays = computeDefaultNRays(app.P);
                app.NofraysEditField.Value = nOfRays;
                app.NRays = nOfRays;
            else
                app.NofraysEditField.Enable = 'on';
                app.NofraysEditFieldLabel.Enable = 'on';
            end
        end

        % Value changed function: ThetamaxEditField
        function ThetamaxEditFieldValueChanged(app, event)
            value = app.ThetamaxEditField.Value;
            
            app.ThetastepEditField.Limits = [0.001, value - ...
                app.ThetaminEditField.Value];
        end

        % Value changed function: ThetaminEditField
        function ThetaminEditFieldValueChanged(app, event)
            value = app.ThetaminEditField.Value;
            
            app.ThetastepEditField.Limits = [0.001, ...
                app.ThetamaxEditField.Value - value];
        end

        % Button pushed function: ChangeButton
        function ChangeButtonPushed(app, event)
            uploadImageFile(app)
            updateImage(app, app.P)
        end

        % Close request function: CTScannerSimulatorUIFigure
        function CTScannerSimulatorUIFigureCloseRequest(app, event)
            closeAllDialogs(app)
            
            delete(app)
        end

        % Button pushed function: SinogramDetailsButton
        function SinogramDetailsButtonPushed(app, event)
            app.SinogramPreviewDialog = ...
                sinogramPreviewApp(app, app.S, app.Th, app.RadCor);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create CTScannerSimulatorUIFigure and hide until all components are created
            app.CTScannerSimulatorUIFigure = uifigure('Visible', 'off');
            app.CTScannerSimulatorUIFigure.Position = [100 100 1278 700];
            app.CTScannerSimulatorUIFigure.Name = 'CT Scanner Simulator';
            app.CTScannerSimulatorUIFigure.CloseRequestFcn = createCallbackFcn(app, @CTScannerSimulatorUIFigureCloseRequest, true);

            % Create PhantomPanel
            app.PhantomPanel = uipanel(app.CTScannerSimulatorUIFigure);
            app.PhantomPanel.Title = 'Phantom';
            app.PhantomPanel.BackgroundColor = [1 1 1];
            app.PhantomPanel.Position = [1 1 426 700];

            % Create ImageAxes
            app.ImageAxes = uiaxes(app.PhantomPanel);
            title(app.ImageAxes, 'Phantom')
            zlabel(app.ImageAxes, 'Z')
            app.ImageAxes.Color = [0 0 0];
            app.ImageAxes.Position = [64 307 315 288];

            % Create TypeofphantomDropDownLabel
            app.TypeofphantomDropDownLabel = uilabel(app.PhantomPanel);
            app.TypeofphantomDropDownLabel.HorizontalAlignment = 'right';
            app.TypeofphantomDropDownLabel.Position = [23 606 105 45];
            app.TypeofphantomDropDownLabel.Text = 'Type of phantom';

            % Create TypeofphantomDropDown
            app.TypeofphantomDropDown = uidropdown(app.PhantomPanel);
            app.TypeofphantomDropDown.Items = {'Shepp-Logan (default)', 'Checkerboard', 'Empty', 'Custom...'};
            app.TypeofphantomDropDown.ItemsData = {'shepp-logan', 'checkerboard', 'empty', 'custom'};
            app.TypeofphantomDropDown.ValueChangedFcn = createCallbackFcn(app, @TypeofphantomDropDownValueChanged, true);
            app.TypeofphantomDropDown.Tooltip = {'Pick a phantom image or choose one of the provided examples'};
            app.TypeofphantomDropDown.Position = [219 610 179 39];
            app.TypeofphantomDropDown.Value = 'shepp-logan';

            % Create PhantomDetailsButton
            app.PhantomDetailsButton = uibutton(app.PhantomPanel, 'push');
            app.PhantomDetailsButton.ButtonPushedFcn = createCallbackFcn(app, @PhantomDetailsButtonPushed, true);
            app.PhantomDetailsButton.BackgroundColor = [0.5686 0.8784 1];
            app.PhantomDetailsButton.FontSize = 16;
            app.PhantomDetailsButton.FontWeight = 'bold';
            app.PhantomDetailsButton.FontColor = [1 1 1];
            app.PhantomDetailsButton.Tooltip = {'View details about the phantom image; Dimensions, min and max values, histogram'};
            app.PhantomDetailsButton.Position = [38 247 362 33];
            app.PhantomDetailsButton.Text = 'Details / Edit';

            % Create ImagenameLabel
            app.ImagenameLabel = uilabel(app.PhantomPanel);
            app.ImagenameLabel.Visible = 'off';
            app.ImagenameLabel.Position = [95 297 72 22];
            app.ImagenameLabel.Text = 'Image name';

            % Create ChangeButton
            app.ChangeButton = uibutton(app.PhantomPanel, 'push');
            app.ChangeButton.ButtonPushedFcn = createCallbackFcn(app, @ChangeButtonPushed, true);
            app.ChangeButton.Visible = 'off';
            app.ChangeButton.Position = [258 297 100 22];
            app.ChangeButton.Text = 'Change';

            % Create PhantomDescription
            app.PhantomDescription = uitextarea(app.PhantomPanel);
            app.PhantomDescription.Editable = 'off';
            app.PhantomDescription.Position = [38 174 360 41];
            app.PhantomDescription.Value = {'Model of a human head; Standard test image used in development of image reconstruction algorithms.'};

            % Create SinogramPanel
            app.SinogramPanel = uipanel(app.CTScannerSimulatorUIFigure);
            app.SinogramPanel.Title = 'Sinogram';
            app.SinogramPanel.BackgroundColor = [1 1 1];
            app.SinogramPanel.Position = [427 1 426 700];

            % Create SinogramAxes
            app.SinogramAxes = uiaxes(app.SinogramPanel);
            title(app.SinogramAxes, 'Sinogram')
            xlabel(app.SinogramAxes, '\theta (degrees)')
            ylabel(app.SinogramAxes, 'x''')
            zlabel(app.SinogramAxes, 'Z')
            app.SinogramAxes.Color = [0 0 0];
            app.SinogramAxes.Position = [17 307 393 288];

            % Create SCANButton
            app.SCANButton = uibutton(app.SinogramPanel, 'push');
            app.SCANButton.ButtonPushedFcn = createCallbackFcn(app, @SCANButtonPushed, true);
            app.SCANButton.BackgroundColor = [0.302 0.7451 0.9333];
            app.SCANButton.FontSize = 26;
            app.SCANButton.FontWeight = 'bold';
            app.SCANButton.FontColor = [1 1 1];
            app.SCANButton.Tooltip = {'Perform a scan of the phantom object with the specified parameters'};
            app.SCANButton.Position = [28 21 361 52];
            app.SCANButton.Text = {'SCAN'; ''};

            % Create ThetaminEditFieldLabel
            app.ThetaminEditFieldLabel = uilabel(app.SinogramPanel);
            app.ThetaminEditFieldLabel.Position = [28 214 59 22];
            app.ThetaminEditFieldLabel.Text = 'Theta min';

            % Create ThetaminEditField
            app.ThetaminEditField = uieditfield(app.SinogramPanel, 'numeric');
            app.ThetaminEditField.ValueChangedFcn = createCallbackFcn(app, @ThetaminEditFieldValueChanged, true);
            app.ThetaminEditField.Tooltip = {'Minimal value of the scanning angle, expressed in degrees.'};
            app.ThetaminEditField.Position = [156 214 46 22];

            % Create ThetamaxEditFieldLabel
            app.ThetamaxEditFieldLabel = uilabel(app.SinogramPanel);
            app.ThetamaxEditFieldLabel.Position = [228 214 103 22];
            app.ThetamaxEditFieldLabel.Text = 'Theta max';

            % Create ThetamaxEditField
            app.ThetamaxEditField = uieditfield(app.SinogramPanel, 'numeric');
            app.ThetamaxEditField.ValueChangedFcn = createCallbackFcn(app, @ThetamaxEditFieldValueChanged, true);
            app.ThetamaxEditField.Tooltip = {'Maximal value of scanning angle, expressed in degrees.'};
            app.ThetamaxEditField.Position = [346 214 44 22];
            app.ThetamaxEditField.Value = 359;

            % Create ThetastepEditFieldLabel
            app.ThetastepEditFieldLabel = uilabel(app.SinogramPanel);
            app.ThetastepEditFieldLabel.Position = [28 183 103 22];
            app.ThetastepEditFieldLabel.Text = 'Theta step';

            % Create ThetastepEditField
            app.ThetastepEditField = uieditfield(app.SinogramPanel, 'numeric');
            app.ThetastepEditField.Limits = [0.001 360];
            app.ThetastepEditField.Tooltip = {'Resolution of scanning. Must be smaller than the value of Theta.'};
            app.ThetastepEditField.Position = [156 183 46 22];
            app.ThetastepEditField.Value = 1;

            % Create NofraysEditFieldLabel
            app.NofraysEditFieldLabel = uilabel(app.SinogramPanel);
            app.NofraysEditFieldLabel.Enable = 'off';
            app.NofraysEditFieldLabel.Position = [228 183 103 22];
            app.NofraysEditFieldLabel.Text = 'N of rays';

            % Create NofraysEditField
            app.NofraysEditField = uieditfield(app.SinogramPanel, 'numeric');
            app.NofraysEditField.Limits = [2 Inf];
            app.NofraysEditField.ValueChangedFcn = createCallbackFcn(app, @NofraysEditFieldValueChanged, true);
            app.NofraysEditField.Enable = 'off';
            app.NofraysEditField.Tooltip = {'(optional) Number of rays in a projection. Minimum number is 3 to obtain an image. Higher N will lead to bigger resolution, but distorted values of absorption coefficient.'};
            app.NofraysEditField.Position = [346 183 44 22];
            app.NofraysEditField.Value = 367;

            % Create SinogramDetailsButton
            app.SinogramDetailsButton = uibutton(app.SinogramPanel, 'push');
            app.SinogramDetailsButton.ButtonPushedFcn = createCallbackFcn(app, @SinogramDetailsButtonPushed, true);
            app.SinogramDetailsButton.BackgroundColor = [0.5686 0.8784 1];
            app.SinogramDetailsButton.FontSize = 16;
            app.SinogramDetailsButton.FontWeight = 'bold';
            app.SinogramDetailsButton.FontColor = [1 1 1];
            app.SinogramDetailsButton.Enable = 'off';
            app.SinogramDetailsButton.Position = [28 247 362 33];
            app.SinogramDetailsButton.Text = 'Details';

            % Create AutoCheckBox
            app.AutoCheckBox = uicheckbox(app.SinogramPanel);
            app.AutoCheckBox.ValueChangedFcn = createCallbackFcn(app, @AutoCheckBoxValueChanged, true);
            app.AutoCheckBox.Text = 'Auto';
            app.AutoCheckBox.Position = [228 153 53 22];
            app.AutoCheckBox.Value = true;

            % Create AddGaussiannoiseCheckBox
            app.AddGaussiannoiseCheckBox = uicheckbox(app.SinogramPanel);
            app.AddGaussiannoiseCheckBox.ValueChangedFcn = createCallbackFcn(app, @AddGaussiannoiseCheckBoxValueChanged, true);
            app.AddGaussiannoiseCheckBox.Tooltip = {'Choose whether to add Gaussian noise to the result of the scanning'};
            app.AddGaussiannoiseCheckBox.Text = 'Add Gaussian noise';
            app.AddGaussiannoiseCheckBox.Position = [28 112 181 22];

            % Create MeanEditFieldLabel
            app.MeanEditFieldLabel = uilabel(app.SinogramPanel);
            app.MeanEditFieldLabel.Enable = 'off';
            app.MeanEditFieldLabel.Position = [28 84 36 22];
            app.MeanEditFieldLabel.Text = 'Mean';

            % Create MeanEditField
            app.MeanEditField = uieditfield(app.SinogramPanel, 'numeric');
            app.MeanEditField.Limits = [0 Inf];
            app.MeanEditField.ValueDisplayFormat = '%11.4g%%';
            app.MeanEditField.Enable = 'off';
            app.MeanEditField.Tooltip = {'Mean value of added noise, expressed as percentage of the amplitude of the result'};
            app.MeanEditField.Position = [150 84 59 22];

            % Create VarianceEditFieldLabel
            app.VarianceEditFieldLabel = uilabel(app.SinogramPanel);
            app.VarianceEditFieldLabel.Enable = 'off';
            app.VarianceEditFieldLabel.Position = [229 84 51 22];
            app.VarianceEditFieldLabel.Text = 'Variance';

            % Create VarianceEditField
            app.VarianceEditField = uieditfield(app.SinogramPanel, 'numeric');
            app.VarianceEditField.Limits = [0 Inf];
            app.VarianceEditField.ValueDisplayFormat = '%11.4g%%';
            app.VarianceEditField.Enable = 'off';
            app.VarianceEditField.Tooltip = {'Variance of added noise, expressed as percentage of the amplitude of the result'};
            app.VarianceEditField.Position = [329 84 60 22];
            app.VarianceEditField.Value = 1;

            % Create ScanningalgorithmLabel
            app.ScanningalgorithmLabel = uilabel(app.SinogramPanel);
            app.ScanningalgorithmLabel.Position = [28 618 113 22];
            app.ScanningalgorithmLabel.Text = 'Scanning algorithm:';

            % Create RadonTransformLabel
            app.RadonTransformLabel = uilabel(app.SinogramPanel);
            app.RadonTransformLabel.FontWeight = 'bold';
            app.RadonTransformLabel.Position = [305 618 104 22];
            app.RadonTransformLabel.Text = 'Radon Transform';

            % Create TomogramPanel
            app.TomogramPanel = uipanel(app.CTScannerSimulatorUIFigure);
            app.TomogramPanel.Enable = 'off';
            app.TomogramPanel.Title = 'Tomogram';
            app.TomogramPanel.BackgroundColor = [1 1 1];
            app.TomogramPanel.Position = [853 1 425 700];

            % Create TomogramAxes
            app.TomogramAxes = uiaxes(app.TomogramPanel);
            title(app.TomogramAxes, 'Tomogram')
            zlabel(app.TomogramAxes, 'Z')
            app.TomogramAxes.Color = [0 0 0];
            app.TomogramAxes.Position = [16 307 394 287];

            % Create RECONSTRUCTButton
            app.RECONSTRUCTButton = uibutton(app.TomogramPanel, 'push');
            app.RECONSTRUCTButton.ButtonPushedFcn = createCallbackFcn(app, @RECONSTRUCTButtonPushed, true);
            app.RECONSTRUCTButton.BackgroundColor = [0.302 0.7451 0.9333];
            app.RECONSTRUCTButton.FontSize = 26;
            app.RECONSTRUCTButton.FontWeight = 'bold';
            app.RECONSTRUCTButton.FontColor = [1 1 1];
            app.RECONSTRUCTButton.Position = [31 21 361 52];
            app.RECONSTRUCTButton.Text = 'RECONSTRUCT';

            % Create TomogramDetailsButton
            app.TomogramDetailsButton = uibutton(app.TomogramPanel, 'push');
            app.TomogramDetailsButton.ButtonPushedFcn = createCallbackFcn(app, @TomogramDetailsButtonPushed, true);
            app.TomogramDetailsButton.BackgroundColor = [0.5686 0.8784 1];
            app.TomogramDetailsButton.FontSize = 16;
            app.TomogramDetailsButton.FontWeight = 'bold';
            app.TomogramDetailsButton.FontColor = [1 1 1];
            app.TomogramDetailsButton.Enable = 'off';
            app.TomogramDetailsButton.Position = [30 247 362 33];
            app.TomogramDetailsButton.Text = 'Details';

            % Create InterpolationDropDownLabel
            app.InterpolationDropDownLabel = uilabel(app.TomogramPanel);
            app.InterpolationDropDownLabel.Position = [31 214 73 22];
            app.InterpolationDropDownLabel.Text = 'Interpolation';

            % Create InterpolationDropDown
            app.InterpolationDropDown = uidropdown(app.TomogramPanel);
            app.InterpolationDropDown.Items = {'Linear (default)', 'Nearest Neighbor', 'Spline', 'Shape-Preserving Piecewise Cubic'};
            app.InterpolationDropDown.ItemsData = {'linear', 'nearest', 'spline', 'pchip'};
            app.InterpolationDropDown.Tooltip = {'Type of interpolation to be used in the backprojection'};
            app.InterpolationDropDown.Position = [152 214 240 22];
            app.InterpolationDropDown.Value = 'linear';

            % Create FiltertypeDropDownLabel
            app.FiltertypeDropDownLabel = uilabel(app.TomogramPanel);
            app.FiltertypeDropDownLabel.Position = [31 173 59 22];
            app.FiltertypeDropDownLabel.Text = 'Filter type';

            % Create FiltertypeDropDown
            app.FiltertypeDropDown = uidropdown(app.TomogramPanel);
            app.FiltertypeDropDown.Items = {'Ram-Lak (default)', 'None', 'Shepp-Logan', 'Cosine', 'Hamming', 'Hann'};
            app.FiltertypeDropDown.ItemsData = {'Ram-Lak', 'none', 'Shepp-Logan', 'Cosine', 'Hamming', 'Hann', ''};
            app.FiltertypeDropDown.Tooltip = {'Type of filter to use for frequency-domain filtering'};
            app.FiltertypeDropDown.Position = [152 173 240 22];
            app.FiltertypeDropDown.Value = 'Ram-Lak';

            % Create ReconstructionalgorithmLabel
            app.ReconstructionalgorithmLabel = uilabel(app.TomogramPanel);
            app.ReconstructionalgorithmLabel.Position = [30 618 144 22];
            app.ReconstructionalgorithmLabel.Text = 'Reconstruction algorithm:';

            % Create InverseRadonTransformLabel
            app.InverseRadonTransformLabel = uilabel(app.TomogramPanel);
            app.InverseRadonTransformLabel.FontWeight = 'bold';
            app.InverseRadonTransformLabel.Position = [262 618 149 22];
            app.InverseRadonTransformLabel.Text = 'Inverse Radon Transform';

            % Show the figure after all components are created
            app.CTScannerSimulatorUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = main

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.CTScannerSimulatorUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.CTScannerSimulatorUIFigure)
        end
    end
end