function fixPaths(con)

replace(con, '`detect`.`_sets`', 'detect_set_path', '\\', '/')
replace(con, '`detect`.`_sets`', 'detect_set_path', 'Y:/', '/')
replace(con, '`detect`.`_electrodes`', 'detect_electrode_file', '\\', '/')
replace(con, '`detect`.`_electrodes`', 'detect_electrode_file', 'Y:/', '/')
replace(con, '`sort`.`_sets`', 'sort_set_path', '\\', '/')


function replace(con, table, field, from, to)

query = ['UPDATE ' table ' SET `' field '` = REPLACE(`' field '`, "' from '", "' to '")'];
mym(con, query)
