#include <tcl.h>


static int
Welcome(ClientData clientData,
        Tcl_Interp *interp,
        int objc,
        Tcl_Obj *CONST objv[])
{
	Tcl_Obj *who;
	Tcl_Obj *result;

	if (objc != 2) {
		Tcl_WrongNumArgs(interp, 1, objv, "who");
		return TCL_ERROR;
	}

  who = objv[1];
  result = Tcl_NewStringObj("Welcome ", 8);
  Tcl_AppendObjToObj(result, who);
  Tcl_SetObjResult(interp, result);
	return TCL_OK;
}


int
Welcome_Init(Tcl_Interp *interp)
{
	Tcl_CreateObjCommand(interp,
                       "welcome",
                       Welcome,
                      (ClientData) NULL,
                      (Tcl_CmdDeleteProc *) NULL);

	if ( Tcl_PkgProvide(interp, "welcome", "0.1") != TCL_OK ) {
		return TCL_ERROR;
	}

	return TCL_OK;
}
