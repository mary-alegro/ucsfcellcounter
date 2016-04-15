function H = recnotch( notch , mode , M , N , W , SV , SH )

if nargin == 4
	W = 1;
	SV = 1 ;
	SH = 1 ;
elseif nargin ~= 7
	error ( ' The number of inputs must be 4 or 7 . ' )
end

if strcmp ( mode , 'both' )
	AV = 0 ;
	AH = 0 ;
elseif strcmp ( mode , 'horizontal' )
	AV = 1 ; 
	AH = 0 ;
elseif strcmp ( mode , 'vertical' )
	AV = 0;
	AH = 1 ; 
end

if iseven(W)
	error ( ' W must be an odd number . ' )
end


H = rectangleReject ( M , N , W , SV , SH , AV , AH ) ;

H = processOutput (notch , H) ;


%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -%
function H = rectangleReject ( M , N , W , SV , SH , AV , AH )

H = ones ( M , N , 'single' ) ;

UC = floor ( M / 2 ) + 1 ;
VC = floor ( N / 2 ) + 1 ;

WL = ( W - 1 ) / 2 ;

H ( UC-WL : UC+WL , 1 : VC - SH ) = AH ;
H ( UC-WL : UC+WL , VC+SH : N ) = AH ;
H ( 1 : UC-SV , VC-WL : VC+WL ) = AV ;
H ( UC+SV : M , VC-WL : VC+WL ) = AV ;

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -%
function H = processOutput( notch , H)

H = ifftshift ( H ) ;

if strcmp ( notch , 'pass' )
	H = 1 - H;
end

