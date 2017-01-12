classdef AlgorithmOptionsPanel < handle
    % AlgorithmOptions - contains algorithm-specific options and associated
    % tearaway.
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties
        popup
    end
    
    properties (SetObservable)
        Smoothness
        BalloonForce
    end
    
    properties (Access = private)
        SmoothSlider
        SmoothText
        
        BalloonSlider
        BalloonText
    end
    
    methods
        function self = AlgorithmOptionsPanel()
            
            panel = toolpack.component.TSPanel(...
                '7px,f:p,8px,50px,f:p:g,50px,8px,f:p,7px',...
                '14px,f:p,-1px,15px,20px,f:p,-1px,15px,15px');
            
            % Create labels for Smoothness and BalloonForce.
            smoothLabel  = toolpack.component.TSLabel('Smoothness');
            balloonLabel = toolpack.component.TSLabel('Direction Force');
            
            smoothLeft   = toolpack.component.TSLabel('Detailed');
            smoothRight  = toolpack.component.TSLabel('Smooth');  
            balloonLeft  = toolpack.component.TSLabel('Grow');    
            balloonRight = toolpack.component.TSLabel('Shrink');  
            
            setToolTipText(smoothLabel ,'Control smoothness of evolving contour');
            setToolTipText(balloonLabel,'Control directional bias of contour towards growing or shrinking');
            
            % Create sliders for Smoothness and BalloonForce.
            minSmoothness   = 0;
            maxSmoothness   = 300;
            startSmoothness = 200;
            self.SmoothSlider  = toolpack.component.TSSlider(minSmoothness,maxSmoothness,startSmoothness);
            self.SmoothSlider.LabelTable = {...
                minSmoothness num2str(0);...
                maxSmoothness num2str(1.5)};
            self.SmoothSlider.PaintLabels = true;
            self.SmoothSlider.MajorTickSpacing = 100;
            self.SmoothSlider.MinorTickSpacing = 3;
            
            addlistener(self.SmoothSlider,'StateChanged',@(hobj,~)self.smoothnessSliderCallback(hobj));
            
            minBalloonness   = -200;
            maxBalloonness   =  200;
            startBalloonness = 0;
            self.BalloonSlider = toolpack.component.TSSlider(minBalloonness,maxBalloonness,startBalloonness);
            self.BalloonSlider.LabelTable = {...
                minBalloonness num2str(-2);...
                maxBalloonness num2str( 2)};
            self.BalloonSlider.PaintLabels = true;
            self.BalloonSlider.MajorTickSpacing = 50;
            self.BalloonSlider.MinorTickSpacing = 5;
            
            addlistener(self.BalloonSlider,'StateChanged',@(hobj,~)self.balloonForceSliderCallback(hobj));
            
            % Create text area for sliders.
            self.SmoothText  = toolpack.component.TSTextField(num2str(startSmoothness*1.5/300),4);
            self.BalloonText = toolpack.component.TSTextField(num2str(startBalloonness/100),4);
            
            addlistener(self.SmoothText ,'ActionPerformed',@(hobj,~)self.smoothnessSliderCallback(hobj));
            addlistener(self.BalloonText,'ActionPerformed',@(hobj,~)self.balloonForceSliderCallback(hobj));
            
            % Layout labels and sliders on panel.
            %first column
            panel.add(smoothLabel ,'xy(2,2)');
            panel.add(balloonLabel,'xy(2,6)');
            
            %second column
            panel.add(self.SmoothSlider ,'xyw(4,2,3)');
            panel.add(smoothLeft        ,'xy(4,4)');
            panel.add(self.BalloonSlider,'xyw(4,6,3)');
            panel.add(balloonLeft       ,'xy(4,8)');
            
            %third column
            panel.add(smoothRight ,'xy(6,4)');
            panel.add(balloonRight,'xy(6,8)');
            
            %fourth column
            panel.add(self.SmoothText ,'xy(8,2)');
            panel.add(self.BalloonText,'xy(8,6)');
            
            self.popup = toolpack.component.TSTearOffPopup(panel);
        end
        
        function updateOptionsPanel(self,algName)
            switch algName
                case 'Chan-Vese'
                    self.Smoothness = 0;
                    self.BalloonForce = 0;
                case 'edge'
                    self.Smoothness = 1;
                    self.BalloonForce = 0.3;
            end
            self.SmoothSlider.Value = self.Smoothness*300/1.5;
            self.SmoothText.Text    = num2str(self.Smoothness);
            
            self.BalloonSlider.Value = self.BalloonForce*100;
            self.BalloonText.Text    = num2str(self.BalloonForce);
        end
    end
    
    % Callback methods
    methods
        function smoothnessSliderCallback(self,obj)
            if isa(obj,'toolpack.component.TSSlider')
                self.Smoothness = obj.Value*1.5/300;
                self.SmoothText.Text = num2str(self.Smoothness);
            elseif isa(obj,'toolpack.component.TSTextField')
                self.Smoothness = str2double(obj.Text);
                self.SmoothSlider.Value = self.Smoothness*300/1.5;
            end
                
        end
        
        function balloonForceSliderCallback(self,obj)
            if isa(obj,'toolpack.component.TSSlider')
                self.BalloonForce = obj.Value/100;
                self.BalloonText.Text = num2str(self.BalloonForce);
            elseif isa(obj,'toolpack.component.TSTextField')
                self.BalloonForce = str2double(obj.Text);
                self.BalloonSlider.Value = self.BalloonForce*100;
            end
        end
    end
end

function setToolTipText(component, tooltipStr)
component.Peer.setToolTipText(tooltipStr)
end