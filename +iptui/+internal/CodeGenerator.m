%   FOR INTERNAL USE ONLY -- This class is intentionally
%   undocumented and is intended for use only within other toolbox
%   classes and functions. Its behavior may change, or the feature
%   itself may be removed in a future release.
%
%CodeGenerator Generate code in MATLAB apps.
%
%   A CodeGenerator object encapsules the methods and properties necessary
%   to generate scripts in functions in MATLAB Apps that have "Export
%   Script" or "Export Function" output options.
%
%   Example
%   -------
%   codeGenObj = iptui.internal.CodeGenerator();
%   codeGenObj.addComment('This is a comment.');
%   codeGenObj.addLine('This is an executable line.');
%   codeGenObj.putCodeInEditor();

% Copyright 2013-2014 The MathWorks, Inc.

classdef CodeGenerator < handle
    
   properties
       
      % String that represents generated code 
      codeString 
      fcnCodeString 
   end
    
   methods
       
       function self = CodeGenerator()
           
           % Initialize string that represents generated code.
           self.codeString = '';
           
       end
       
       function addHeader(self,appName)
           %addHeader Add header at top of generated code
           %
           %  obj.addHeader(appName) adds a comment header to the top of
           %  the generated code. This header informs a user that the code
           %  was auto-generated by the app named appName.
           
           string = sprintf(['%% Auto-generated by ', ...
               '%s app on %s'], appName, date);
           
           self.addLine(string);
           self.addLine(['%' repmat('-',1,length(string)-1)]);
           self.addReturn();
       end
       
       function addComment(self,commentString)
           %addComment Add comment to generated code
           %
           %  obj.addComment(commentString) adds a comment line defined by
           %  commentString to the generated code.
           
           self.addReturn()
           self.addLine(['% ', commentString])
       end
       
       function addCommentBlock(self, varargin)
           %addCommentBlock Add comment spanning multiple lines to generated code
           %
           %  obj.addCommentBlock(commentLine1String, commentLine2String, ...)
           %  adds the comments in commentLine1String, etc. to the
           %  generated code. A blank line is inserted before the first
           %  comment line but not between subsequent lines. To get a
           %  commented blank line, provide an empty string.
           
           self.addReturn()
           for idx = 2:nargin
               self.addLine(['% ', varargin{idx-1}])
           end
           
       end
       
       function addLine(self,lineString)
           %addLine  Add line to generated code.
           %
           %  obj.addLine(lineString) adds a line defined by lineString to
           %  the generated code.
           
           self.addReturn()
           self.codeString = [self.codeString,lineString];
       end
       
       function addLineWithoutWhitespace(self,lineString)
           %addLineWithoutWhitespace  Add line without preceding newline.
           %
           %  obj.addLineWithoutWhitespace(lineString) adds a line defined by
           %  lineString to the generated code without a preceding newline.
           
           self.codeString = [self.codeString,lineString];
       end
       
       function addReturn(self)
           %addReturn Add a new line to generated code
           %
           %  obj.addReturn() adds a carriage return to the generated code.
           
           self.codeString = [self.codeString, sprintf('\n')];
       end
       
       function str = getCodeString(self)
           %getCodeString Return generated code
           %
           %  obj.getCodeString() returns generated code as a string.

           str = self.codeString;
       end
       
       function addFunctionDeclaration(self,fcnname,varargin)
           %addFunctionDeclaration Add function declaration to generated
           %code.
           %
           % obj.addFunctionDeclaration(fcnName,inArgs,outArgs,h1Line)
           % adds a function declaration for a function named fcnName with
           % input argument names inputArgs (specified as a cellstr),
           % output argument names outputArgs (specified as a cellstr) and
           % H1 line specified by h1Line.
           
           inputargs  = '';
           outputargs = '';
           h1line     = '';
           if nargin==3
               % obj.addFunctionDeclaration(fcnName,inArgs)
               inputargs  = varargin{1};
           elseif nargin==4
               % obj.addFunctionDeclaration(fcnName,inArgs,outArgs)
               inputargs  = varargin{1};
               outputargs = varargin{2};
           elseif nargin==5
               % obj.addFunctionDeclaration(fcnName,inArgs,outArgs,h1Line)
               inputargs  = varargin{1};
               outputargs = varargin{2};
               h1line     = varargin{3};
           end
           
           %Process input list.
           if ~isempty(inputargs)
               inputargs = strjoin(inputargs,',');
           end
           inputargs = ['(',inputargs,')'];
           
           %Process output list.
           if ~isempty(outputargs)
               outputargs = strjoin(outputargs,',');
               outputargs = ['[',outputargs,'] '];
               outputargs = [outputargs,'= '];
           end
           
           % Add function declaration.
           self.addLineWithoutWhitespace(sprintf('function %s%s%s',outputargs,fcnname,inputargs));
           
           % Add H1 line.
           if ~isempty(h1line)
               h1line = ['%',fcnname,' ', h1line];
               self.addLine(h1line);
           end
           
       end
       
       function addSyntaxHelp(self,fcnname,description,inputargs,varargin)
           %addSyntaxHelp Add syntax help to generated code
           %
           % obj.addSyntaxHelp(fcnName,description,inputArgs,outputArgs,length)
           % adds syntax help to function fcnName for the syntax with
           % inputs inputArgs, outputs outputArgs using description as the
           % syntax description. Comment wrapping for syntax help is
           % defaulted to 75 characters per line, unless length is
           % specified. Note that this needs to be called right after
           % addFunctionDeclaration.
           
           charsperline = 75;
           if nargin==4
               outputargs = '';
           elseif nargin==5
               outputargs = varargin{1};
           elseif nargin==6
               outputargs = varargin{1};
               charsperline = varargin{2};
           end
           
           %Process input list.
           if ~isempty(inputargs)
               inputargs = strjoin(inputargs,',');
           end
           inputargs = ['(',upper(inputargs),')'];
           
           %Process output list.
           if ~isempty(outputargs)
               outputargs = strjoin(outputargs,',');
               outputargs = ['[',outputargs,'] '];
               outputargs = [upper(outputargs),'= '];
           end
           
           % Add code folding capability.
           syntax = [outputargs,fcnname,inputargs];
           
           stringToWrap = [syntax ' ' description];
           
           % split the string into words.
           words = strsplit(stringToWrap,' ');
           
           lines = words(1);
           % for each word, add it to a line till the total length becomes
           % charsperline.
           for n = 2 : length(words)
               if length(lines{end})+length(words{n})>charsperline-2
                   lines{end+1} = ''; %#ok<AGROW>
               end
               lines{end} = [lines{end}, ' ', words{n}];
           end
           
           self.addLine(['%  ' lines{1}]);
           for l = 2 : length(lines)
               self.addLine(['% ' lines{l}]);
           end
       end

       function addSubFunction(self,functionString)
           %addSubFunction Add a new sub-function to generated code
           %
           % obj.addSubFunction(functionString) adds a sub-function at the
           % end of generated code. Typically, functionString is generated
           % from another CodeGenerator object.

           if isempty(self.fcnCodeString)
               self.fcnCodeString{1} = functionString;
           else
               self.fcnCodeString{end+1} = functionString;
           end
       end

       function putCodeInEditor(self)
           %putCodeInEditor Puts generated code in MATLAB editor
           %
           %  obj.putCodeInEditor() puts the generated code in the MATLAB
           %  editor and auto indents the code.
           
           if ~isempty(self.fcnCodeString)
              % Add new lines
              self.addReturn()
              self.addReturn()

              % Add sub-functions  
              for n = 1 : numel(self.fcnCodeString)
                self.codeString = [self.codeString self.fcnCodeString{n}];
                self.addReturn()
              end
           end

           editorDoc = matlab.desktop.editor.newDocument(self.codeString);
           editorDoc.smartIndentContents;
       end
       
   end
    
end
