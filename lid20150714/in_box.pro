function in_box, x, y, box


compile_opt strictarr, strictarrsubs


return, (x GE box[0] && x LE box[2] && y GE box[1] && y LE box[3])


end
