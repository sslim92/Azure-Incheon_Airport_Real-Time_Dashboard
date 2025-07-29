source(output(
		timestamp as string,
		date as string,
		time as string,
		report_type as string,
		raw_text as string,
		station_type as string,
		status as string,
		permissible_usage as string,
		temperature as string,
		dew_point_temperature as string,
		qnh as string,
		mean_wind_speed as string,
		max_wind_speed as string,
		mean_wind_direction as string,
		wind_counter_clock_direction as string,
		wind_clock_direction as string,
		horizontal_visibility as string,
		clouds as string,
		change_indicator as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	isolationLevel: 'READ_UNCOMMITTED',
	format: 'table') ~> source1
select1 derive(year = left(timestamp, 4),
		month = substring(timestamp, 6, 2),
		day = substring(timestamp, 9, 2),
		time = right(timestamp, 8),
		max_wind_speed = iif(max_wind_speed == '-', mean_wind_speed, max_wind_speed),
		wind_counter_clock_direction = iif(wind_counter_clock_direction == '-', mean_wind_direction, wind_counter_clock_direction),
		wind_clock_direction = iif(wind_clock_direction == '-', mean_wind_direction, wind_clock_direction)) ~> derivedColumn1
filter1 select(mapColumn(
		timestamp,
		observ_date = date,
		observ_time = time,
		temperature,
		dew_point_temperature,
		qnh,
		mean_wind_speed,
		max_wind_speed,
		mean_wind_direction,
		wind_counter_clock_direction,
		wind_clock_direction,
		horizontal_visibility,
		clouds,
		change_indicator
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> select1
derivedColumn2 select(mapColumn(
		timestamp,
		year,
		month,
		day,
		time,
		observ_date,
		observ_time,
		temperature,
		dew_point_temperature,
		qnh,
		mean_wind_speed,
		max_wind_speed,
		mean_wind_direction,
		wind_counter_clock_direction,
		wind_clock_direction,
		horizontal_visibility,
		clouds,
		change_indicator,
		weather_label
	),
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> select2
window1 filter(rank == 1) ~> filter1
source1 window(desc(timestamp, true),
	rank = rowNumber()) ~> window1
derivedColumn1 derive(weather_label = iif(
  startsWith(split(clouds, ' ')[0], 'OVC') || startsWith(split(clouds, ' ')[1], 'OVC') || startsWith(split(clouds, ' ')[2], 'OVC') || startsWith(split(clouds, ' ')[3], 'OVC')
  || toInteger(horizontal_visibility) < 8000, '흐림',
  iif(
    startsWith(split(clouds, ' ')[0], 'BKN') || startsWith(split(clouds, ' ')[1], 'BKN') || startsWith(split(clouds, ' ')[2], 'BKN') || startsWith(split(clouds, ' ')[3], 'BKN')
    || (
	 (startsWith(split(clouds, ' ')[0], 'FEW') || startsWith(split(clouds, ' ')[1], 'FEW') || startsWith(split(clouds, ' ')[2], 'FEW') || startsWith(split(clouds, ' ')[3], 'FEW')
	 || startsWith(split(clouds, ' ')[0], 'SCT') || startsWith(split(clouds, ' ')[1], 'SCT') || startsWith(split(clouds, ' ')[2], 'SCT') || startsWith(split(clouds, ' ')[3], 'SCT')
    ) && toInteger(horizontal_visibility) < 8000
    ), '구름많음',
    iif(
	 (
	   (startsWith(split(clouds, ' ')[0], 'FEW') || startsWith(split(clouds, ' ')[1], 'FEW') || startsWith(split(clouds, ' ')[2], 'FEW') || startsWith(split(clouds, ' ')[3], 'FEW')
	   || startsWith(split(clouds, ' ')[0], 'SCT') || startsWith(split(clouds, ' ')[1], 'SCT') || startsWith(split(clouds, ' ')[2], 'SCT') || startsWith(split(clouds, ' ')[3], 'SCT')
	 ) && toInteger(horizontal_visibility) >= 8000
	 ), '구름조금',
	 iif(
	   startsWith(split(clouds, ' ')[0], 'CAVOK') || startsWith(split(clouds, ' ')[1], 'CAVOK') || startsWith(split(clouds, ' ')[2], 'CAVOK') || startsWith(split(clouds, ' ')[3], 'CAVOK')
	   || isNull(clouds) || clouds == '' || toInteger(horizontal_visibility) >= 10000, '맑음',
	   '기타'
	 )
    )
  )
)) ~> derivedColumn2
select2 sink(allowSchemaDrift: true,
	validateSchema: false,
	input(
		timestamp as string,
		year as string,
		month as string,
		day as string,
		time as string,
		observ_date as string,
		observ_time as string,
		temperature as string,
		dew_point_temperature as string,
		qnh as string,
		mean_wind_speed as string,
		max_wind_speed as string,
		mean_wind_direction as string,
		wind_counter_clock_direction as string,
		wind_clock_direction as string,
		horizontal_visibility as string,
		clouds as string,
		change_indicator as string
	),
	deletable:false,
	insertable:true,
	updateable:false,
	upsertable:false,
	format: 'table',
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true) ~> sink1