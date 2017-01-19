classdef SegmentRefineEventLogger < handle
    %SegmentRefineEventLogger - Create an event log of segmentation and
    %refine operations completed during each session of the
    %imageSegmenter for code generation.
    
    % Copyright 2014, The MathWorks Inc.
    
    properties
        EventStruct
    end
    
    methods
        %------------------------------------------------------------------
        % Construction
        %------------------------------------------------------------------
        function self = SegmentRefineEventLogger()
            
            % Initialize Event structure
            self.EventStruct = [];
        end
        
        %------------------------------------------------------------------
        % Event Logging
        %------------------------------------------------------------------
        function addSegmentEvent(self,method,iterations)
            %addSegmentEvent - Add segmentation event to log on segment.
            
            data.method = method;
            data.N      = iterations;
            
            evt.op = 'Segment';
            evt.data = data;
            
            if isempty(self.EventStruct)
                self.EventStruct = evt;
            else
                self.EventStruct(end+1) = evt;
            end
        end
        
        function addRefineEvent(self,clearborders,fillholes,minsize,maxsize,minfilter,maxfilter)
            %addRefineEvent - Add refine event to log on accepting refine
            %mask.
            
            data.clearborders = clearborders;
            data.fillholes    = fillholes;
            data.minsize      = minsize;
            data.maxsize      = maxsize;
            data.minfilter    = minfilter;
            data.maxfilter    = maxfilter;
            
            evt.op = 'Refine';
            evt.data = data;
            
            if isempty(self.EventStruct)
                self.EventStruct = evt;
            else
                self.EventStruct(end+1) = evt;
            end
        end
        
        function clearEventLog(self)
            %clearEventLog - Clear event log when new mask is initialized
            %or image is loaded.
            
            self.EventStruct = [];
        end
        
        %------------------------------------------------------------------
        % Code Generation
        %------------------------------------------------------------------
        function addCodeToGenerator(self,generator)
            
            EvtStruct = self.EventStruct;
            
            % If there are no event structs, add stub code to have a valid
            % BW.
            if isempty(EvtStruct)
                addStubCode(generator);
            end
            
            for n = 1 : numel(EvtStruct)
                
                if n==1
                    in  = 'mask';
                    out = 'BW';
                else
                    in  = 'BW';
                    out = 'BW';
                end

                switch EvtStruct(n).op
                    case 'Segment'
                        addSegmentCode(generator,EvtStruct(n).data,in,out);
                    case 'Refine'
                        addRefineCode(generator,EvtStruct(n).data,in,out);
                end     
            end
        end
        
    end
end    

%--------------------------------------------------------------------------
% Code Generation
%--------------------------------------------------------------------------
function addSegmentCode(generator,metadata,in,out)

method = metadata.method;
N      = metadata.N;

generator.addComment('Evolve segmentation');
generator.addLine(sprintf('%s = activecontour(im, %s, %s, ''%s'');',out,in,num2str(N),method));
end

function addRefineCode(generator,metadata,in,out)

clearborders = metadata.clearborders;
fillholes    = metadata.fillholes;

% This flag is used to indicate whether to continue using different input
% and output variables or use only the output variable in the generated
% code. After the first operation that is performed, we continue using the
% output variable as the input to subsequent operations.
useOutVariable = false;

if clearborders
    generator.addComment('Suppress components connected to image border');
    generator.addLine(sprintf('%s = imclearborder(%s);',out,in));

    useOutVariable = true;
end

if useOutVariable
    in = out;
end

if fillholes
    generator.addComment('Fill holes');
    generator.addLine(sprintf('%s = imfill(%s, ''holes'');',out,in));
    
    useOutVariable = true;
end

if useOutVariable
    in = out;
end

minsize   = metadata.minsize;
maxsize   = metadata.maxsize;
minfilter = metadata.minfilter;
maxfilter = metadata.maxfilter;

% If the minimum region slider was not moved, range(1) should be 0 in the
% call to bwareafilt.
if ~minfilter
    minsize = 0;
end

% If the maximum region slider was not moved, range(2) should be Inf in the
% call to bwareafilt.
if ~maxfilter
    maxsize = Inf;
end

% If atleast one of the sliders was moved, add code for bwareafilt.
if minfilter || maxfilter
    generator.addComment('Filter components by area');
    generator.addLine(sprintf('%s = bwareafilt(%s, [%s %s]);',out,in,num2str(minsize),num2str(maxsize)));
else
    % Else, we don't need any code, unless this is the first event
    % (indicated by in~=out) and no fill holes or clear border has
    % happened.
    if ~strcmp(in,out) && ~useOutVariable
        generator.addLine(sprintf('%s = %s;',out,in));
    end
end
end

function addStubCode(generator)

generator.addLine('BW = mask;');
end
