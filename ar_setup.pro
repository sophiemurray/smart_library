;A setup file that makes the environment variables to run the code
;To get a structure of the system variables do: IDL> ar_setup,defvar=vars,/get
;To check if setup has been run already: IDL> ar_setup,status=status,/get
pro ar_setup, ar_path=inar_path, ar_param=inar_param, ar_struct=inar_struct, $
	get=get, defvars=outvars, status=outstatus

;readcol,''

;S Murray - changed Paul's default directory for cron job
smart_path = '/home/h05/smurray/codes/SMART/trunk/smart_library/'

;Set default variables
sysvars={ar_path:['!AR_PATH',smart_path], ar_param:['!AR_PARAM','ar_param.txt'], ar_struct:['!AR_STRUCT','ar_struct_param.txt']}

if keyword_set(get) then begin
	;check if setup has been run
	status=1
	defsysv,(sysvars.ar_path)[0],exist=defsys
	status=status < defsys
	if status then ex=execute('sysvars.ar_path=[(sysvars.ar_path)[0],'+(sysvars.ar_path)[0]+']')
	
	defsysv,(sysvars.ar_param)[0],exist=defsys
	status=status < defsys
	if status then ex=execute('sysvars.ar_param=[(sysvars.ar_param)[0],'+(sysvars.ar_param)[0]+']')

	defsysv,(sysvars.ar_struct)[0],exist=defsys
	status=status < defsys
	if status then ex=execute('sysvars.ar_struct=[(sysvars.ar_struct)[0],'+(sysvars.ar_struct)[0]+']')

	
	outstatus=status
	
	;output defaults
	outvars=sysvars
	return
endif

;Allow for variable names to be set externally
if n_elements(inar_path) eq 1 then ar_path=inar_path else ar_path=(sysvars.ar_path)[1]
if n_elements(inar_param) eq 1 then ar_param=inar_param else ar_param=(sysvars.ar_param)[1]
if n_elements(inar_struct) eq 1 then ar_struct=inar_struct else ar_struct=(sysvars.ar_struct)[1]

;Set the environment variables
DEFSYSV, (sysvars.ar_path)[0], ar_path
DEFSYSV, (sysvars.ar_param)[0], ar_param
DEFSYSV, (sysvars.ar_struct)[0], ar_struct

end
