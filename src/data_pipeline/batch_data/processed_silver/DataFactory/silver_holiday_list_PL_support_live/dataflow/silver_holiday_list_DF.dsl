source(output(
		date as string,
		seq as string,
		date_kind as string,
		is_holiday as string,
		date_name as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> source1
source1 derive(year = left(date, 4),
		month = substring(date, 5, 2),
		day = right(date, 2),
		date_kind_fix = case(date_kind == '01', '02', date_kind == '02', '01', date_kind)) ~> derivedColumn1
sort1 select(mapColumn(
		date,
		year,
		month,
		day,
		seq,
		date_kind = date_kind_fix,
		date_name
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> select1
derivedColumn1 sort(asc(date, true),
	asc(date_kind_fix, true)) ~> sort1
select1 window(over(date),
	asc(date_kind, true),
	seq = rowNumber()) ~> window1
window1 sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		date as string,
		seq as string,
		date_kind as string,
		date_name as string
	),
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	format: 'table',
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> sink1