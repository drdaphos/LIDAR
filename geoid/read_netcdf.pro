function read_netcdf, ncfile

;data = read_netcdf(ncfile)

 nCDFObject = Obj_New('NCDF_DATA', ncfile)
 data = nCDFObject -> ReadFile(ncfile)

 obj_destroy, nCDFObject
 
 return, data

end
