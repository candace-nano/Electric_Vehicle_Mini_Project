--Creating a temp table to view only relevant records & clean up the data
--Excluding records with inaccurate/impossible sale prices
/**Run the where clause temp table query every time upon reopening the file**/
SELECT *
INTO #temp_EV_title_and_reg
FROM [TRAINING].[Electric_Vehicle_Title_and_Registration_Activity]
	WHERE (([New_or_Used_Vehicle] = 'New' AND [Sale_Price] BETWEEN 26000 AND 270000)
		OR ([New_or_Used_Vehicle] = 'Used' AND [Sale_Price] BETWEEN 3500 AND 270000))
	AND ([Odometer_Code] = 'Actual Mileage')
	AND ([Odometer_Reading] < 300000)
	AND ([State_of_Residence] = 'WA');

SELECT *
FROM #temp_EV_title_and_reg;


--Creating a temp table to view only relevant records & clean up the data
/**Run the where clause temp table query every time upon reopening the file**/

----ALTER TABLE [TRAINING].[Electric_Vehicle_Population_Data]
----ALTER COLUMN [Electric_Range] bigint;
SELECT *
INTO #temp_EV_pop_data
FROM [TRAINING].[Electric_Vehicle_Population_Data]
	WHERE [Electric_Range] <> 0;

SELECT *
FROM #temp_EV_pop_data;


--Running the tables together to view both at the same timeto determine what fields I want to bring in on the join
SELECT *
FROM #temp_EV_pop_data;

SELECT *
FROM #temp_EV_title_and_reg;


--Performing an inner join statement to connect the two tables on VIN#, and exclude all possible NULLS 
----(VINs from #temp_EV_pop_data that didnt have a match with data from #temp_EV_title_and_reg)
/**Run the join temp table query every time upon reopening the file**/
SELECT 
	#temp_EV_pop_data.VIN,
	#temp_EV_title_and_reg.County,
	#temp_EV_title_and_reg.City,
	#temp_EV_title_and_reg.State_of_Residence,
	#temp_EV_title_and_reg.Postal_Code,
	#temp_EV_pop_data.Model_Year,
	#temp_EV_pop_data.Make,
	#temp_EV_pop_data.Model,
	#temp_EV_pop_data.Electric_Vehicle_Type,
	#temp_EV_pop_data.Electric_Range,
	#temp_EV_title_and_reg.Odometer_Reading,
	#temp_EV_title_and_reg.New_or_Used_Vehicle,
	#temp_EV_title_and_reg.Sale_Price,
	#temp_EV_title_and_reg.Sale_Date,
	#temp_EV_title_and_reg.Transaction_Year
INTO #temp_join
FROM #temp_EV_pop_data
INNER JOIN #temp_EV_title_and_reg
	ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN;

SELECT *
FROM #temp_join;






---------------
/**Data exploration time pt.1 !!! - results WITH #temp_join table**/
/**Determining what year had the most sales**/
WITH t1 AS 
	(SELECT 
		Transaction_year,
		COUNT(*) AS Transaction_year_total_sales
	FROM #temp_join
		GROUP BY Transaction_year)

SELECT 
	Transaction_year,
	Transaction_year_total_sales,
	CONCAT(CAST(CAST((Transaction_year_total_sales*100) as decimal(11, 2))/(SELECT SUM(Transaction_year_total_sales) FROM t1) as decimal(11, 2)), '%') AS Percentage_of_total_sales_overall 
FROM t1
	ORDER BY Transaction_year_total_sales DESC;
	--ANSWER: 2018 had the most transactions at 27.49%, followed by 2019 at 23.09%, then 2020 at 16.58%



/**Determining the amount of each Electric_vehicle_type purchased**/
WITH t2 AS
	(SELECT 
		Electric_vehicle_type,
		COUNT(*) AS Electric_vehicle_type_total
	FROM #temp_join
		GROUP BY Electric_vehicle_type)

SELECT
	Electric_vehicle_type,
	Electric_vehicle_type_total,
	CONCAT(CAST(CAST((Electric_vehicle_type_total*100) as decimal(11, 2))/(SELECT SUM(Electric_vehicle_type_total) FROM t2) as decimal(11, 2)), '%') AS Percentage_of_electric_vehicle_type_total
FROM t2
	ORDER BY Electric_vehicle_type_total DESC;
	--ANSWER: Electric Vehicle (BEV) at 88.62%, followed by Plug-in Hybrid Electric Vehicle (PHEV) at 11.38%



/**Most commonly purchased Battery Electric Vehicle (BEV) considering year**/
WITH t3 AS
	(SELECT 
		CONCAT(Model_Year,' ', Make,' ', Model) AS Yr_make_model_concat,
		COUNT(*) AS Yr_make_model_total
	FROM #temp_join
		WHERE Electric_vehicle_type = 'Battery Electric Vehicle (BEV)'
		GROUP BY CONCAT(Model_Year,' ', Make,' ', Model))

SELECT
	Yr_make_model_concat,
	Yr_make_model_total,
	CONCAT(CAST(CAST((Yr_make_model_total*100) as decimal(11, 2))/(SELECT SUM(Yr_make_model_total) FROM t3) as decimal(11, 2)), '%') AS Percentage_of_BEV_yr_make_model_total
FROM t3
	ORDER BY Yr_make_model_total DESC;
	--ANSWER: 2018 TESLA MODEL 3 at 33.29%, followed by 2019 TESLA MODEL 3 at 15.56%, then 2020 TESLA MODEL 3 at 9.93%

	

/**Most commonly purchased Battery Electric Vehicle (BEV) NOT considering year**/
WITH t4 AS
	(SELECT 
		CONCAT(Make,' ', Model) AS Make_model_concat,
		COUNT(*) AS Make_model_total
	FROM #temp_join
		WHERE Electric_vehicle_type = 'Battery Electric Vehicle (BEV)'
		GROUP BY CONCAT(Make,' ', Model))

SELECT
	Make_model_concat,
	Make_model_total,
	CONCAT(CAST(CAST((Make_model_total*100) as decimal(11, 2))/(SELECT SUM(Make_model_total) FROM t4) as decimal(11, 2)), '%') AS Percentage_of_BEV_make_model_total
FROM t4		
	ORDER BY Make_model_total DESC;
	--ANSWER: TESLA MODEL 3 at 58.79%, followed by NISSAN LEAF at 24.47%, then TESLA MODEL Y at 5.69%



/**Most commonly purchased Plug-in Hybrid Electric Vehicle (PHEV) considering year**/
WITH t5 AS
	(SELECT 
		CONCAT(Model_Year,' ', Make,' ', Model) AS Yr_make_model_concat,
		COUNT(*) AS Yr_make_model_total
	FROM #temp_join
		WHERE Electric_vehicle_type = 'Plug-in Hybrid Electric Vehicle (PHEV)'
		GROUP BY CONCAT(Model_Year,' ', Make,' ', Model))

SELECT
	Yr_make_model_concat,
	Yr_make_model_total,
	CONCAT(CAST(CAST((Yr_make_model_total*100) as decimal(11, 2))/(SELECT SUM(Yr_make_model_total) FROM t5) as decimal(11, 2)), '%') AS Percentage_of_PHEV_yr_make_model_total
FROM t5
	ORDER BY Yr_make_model_total DESC;
	--ANSWER: 2017 TOYOTA PRIUS PRIME at 11.19%, followed by 2023 JEEP WRANGLER at 8.62%, then 2017 CHEVROLET VOLT at 7.41%



/**Most commonly purchased Plug-in Hybrid Electric Vehicle (PHEV) NOT considering year**/
WITH t6 AS
	(SELECT 
		CONCAT(Make,' ', Model) AS Make_model_concat,
		COUNT(*) AS Make_model_total
	FROM #temp_join
		WHERE Electric_vehicle_type = 'Plug-in Hybrid Electric Vehicle (PHEV)'
		GROUP BY CONCAT(Make,' ', Model))

SELECT
	Make_model_concat,
	Make_model_total,
	CONCAT(CAST(CAST((Make_model_total*100) as decimal(11, 2))/(SELECT SUM(Make_model_total) FROM t6) as decimal(11, 2)), '%') AS Percentage_of_PHEV_make_model_total
FROM t6		
	ORDER BY Make_model_total DESC;
	--ANSWER: TOYOTA PRIUS PRIME at 20.19%, followed by CHEVROLET VOLT at 13.30%, then JEEP WRANGLER at 13.12%



/**Most commonly purchased vehicle overall considering year**/
WITH t7 AS
	(SELECT 
		CONCAT(Model_Year,' ', Make,' ', Model) AS Yr_make_model_concat,
		Electric_vehicle_type,
		COUNT(*) AS Yr_make_model_total
	FROM #temp_join
		GROUP BY 
			CONCAT(Model_Year,' ', Make,' ', Model),
			Electric_vehicle_type)

SELECT
	Yr_make_model_concat,
	Electric_vehicle_type,
	Yr_make_model_total,
	CONCAT(CAST(CAST((Yr_make_model_total*100) as decimal(11, 2))/(SELECT SUM(Yr_make_model_total) FROM t7) as decimal(11, 2)), '%') AS Percentage_of_yr_make_model_total_overall
FROM t7
	ORDER BY Yr_make_model_total DESC;
	--ANSWER: 2018 TESLA MODEL 3 at 29.50%, followed by 2019 TESLA MODEL 3 at 13.79%, then 2020 TESLA MODEL 3 at 8.80%



/**Most commonly purchased vehicle overall NOT considering year**/
WITH t8 AS
	(SELECT 
		CONCAT(Make,' ', Model) AS Make_model_concat,
		Electric_vehicle_type,
		COUNT(*) AS Make_model_total
	FROM #temp_join
		GROUP BY 
			CONCAT(Make,' ', Model),
			Electric_vehicle_type)

SELECT
	Make_model_concat,
	Electric_vehicle_type,
	Make_model_total,
	CONCAT(CAST(CAST((Make_model_total*100) as decimal(11, 2))/(SELECT SUM(Make_model_total) FROM t8) as decimal(11, 2)), '%') AS Percentage_of_make_model_total_overall
FROM t8		
	ORDER BY Make_model_total DESC;
	--ANSWER: TESLA MODEL 3 at 52.10%, followed by NISSAN LEAF at 21.69%, then TESLA MODEL Y at 5.05%



/**City in Washington that has the highest electric vehicle purchases**/
WITH t9 AS
	(SELECT 
		City,
		County,
		COUNT(*) AS City_total
	FROM #temp_join
		GROUP BY 
			City,
			County)

SELECT
	City,
	County,
	City_total,
	CONCAT(CAST(CAST((City_total*100) as decimal(11, 2))/(SELECT SUM(City_total) FROM t9) as decimal(11, 2)), '%') AS Percentage_of_city_total
FROM t9		
	ORDER BY City_total DESC;
	--ANSWER: Seattle at 19.37%, followed by Bellevue at 6.09%, then Redmond at 4.75%



/**County in Washington that has the highest electric vehicle purchases**/
WITH t10 AS
	(SELECT 
		County,
		COUNT(*) AS County_total
	FROM #temp_join
		GROUP BY County)

SELECT
	County,
	County_total,
	CONCAT(CAST(CAST((County_total*100) as decimal(11, 2))/(SELECT SUM(County_total) FROM t10) as decimal(11, 2)), '%') AS Percentage_of_county_total
FROM t10		
	ORDER BY County_total DESC;
	--ANSWER: King at 56.41%, followed by Snohomish at 11.22%, then Pierce at 7.31%



/**Average, max, & min Sale_price for NEW vehicles per year per Electric_vehicle_type**/
SELECT 
	Transaction_Year,
	Electric_Vehicle_Type,
	FORMAT(AVG(CAST((Sale_price) as bigint)), 'C') AS AVG_sale_price,
	FORMAT(CAST(MAX((Sale_price)) as bigint), 'C') AS MAX_sale_price,
	FORMAT(CAST(MIN((Sale_price)) as bigint), 'C') AS MIN_sale_price
FROM #temp_join
	WHERE New_or_Used_Vehicle = 'New'
	GROUP BY 
		Transaction_Year,
		Electric_Vehicle_Type
	ORDER BY 
		Electric_Vehicle_Type, 
		Transaction_Year DESC;
	--AVERAGE SALE PRICE (BEV): 
		--highest; 2023 - $66,163.00
		--lowest; 2021 - $42,858.00
	--MAX SALE PRICE (BEV): 
		--highest; 2019 - $260,950.00
		--lowest; 2023 - $121,995.00
	--MIN SALE PRICE (BEV): 
		--highest; 2023 - $42,900.00
		--lowest; 2017, 2019-2021 - $26,000.00

	--AVERAGE SALE PRICE (PHEV): 
		--highest; 2022 - $64,645.00 
		--lowest; 2018 - $35,007.00
	--MAX SALE PRICE (PHEV): 
		--highest; 2022 - $250,440.00 
		--lowest; 2017 - $98,500.00
	--MIN SALE PRICE (PHEV): 
		--highest; 2016 - $29,255.00
		--lowest; 2017-2020 - $26,000.00



/**Average, max, & min Sale_price for USED vehicles per year per Electric_vehicle_type**/
SELECT 
	Transaction_Year,
	Electric_Vehicle_Type,
	FORMAT(AVG(CAST((Sale_price) as bigint)), 'C') AS AVG_sale_price,
	FORMAT(CAST(MAX((Sale_price)) as bigint), 'C') AS MAX_sale_price,
	FORMAT(CAST(MIN((Sale_price)) as bigint), 'C') AS MIN_sale_price
FROM #temp_join
	WHERE New_or_Used_Vehicle = 'Used'
	GROUP BY 
		Transaction_Year,
		Electric_Vehicle_Type
	ORDER BY 
		Electric_Vehicle_Type, 
		Transaction_Year DESC;
	--AVERAGE SALE PRICE (BEV): 
		--highest; 2022 - $38,880.00
		--lowest; 2017 - $12,554.00
	--MAX SALE PRICE (BEV): 
		--highest; 2020 - $215,590.00
		--lowest; 2016 - $99,570.00
	--MIN SALE PRICE (BEV): 
		--highest; 2016 - $5,000.00
		--lowest; 2017-2023 - $3,500.00

	--AVERAGE SALE PRICE (PHEV): 
		--highest; 2022 - $32,228.00 
		--lowest; 2019 - $19,621.00
	--MAX SALE PRICE (PHEV): 
		--highest; 2018 - $170,000.00 
		--lowest; 2017 - $99,000.00
	--MIN SALE PRICE (PHEV): 
		--highest; 2016 - $4,039.00
		--lowest; 2017, 2019, 2022-2023 - $3,500.00

	

/**Average, max, & min Sale_price for ALL vehicles per Electric_vehicle_type**/
SELECT 
	Electric_Vehicle_Type,
	FORMAT(AVG((Sale_price)), 'C') AS AVG_sale_price,
	FORMAT(MAX((Sale_price)), 'C') AS MAX_sale_price,
	FORMAT(MIN((Sale_price)), 'C') AS MIN_sale_price
FROM #temp_join
	GROUP BY Electric_Vehicle_Type;
	--AVERAGE SALE PRICE (BEV): $43,165.00
	--MAX SALE PRICE (BEV): $260,950.00
	--MIN SALE PRICE (BEV): $3500.00

	--AVERAGE SALE PRICE (PHEV): $39,806.00
	--MAX SALE PRICE (PHEV): $250,440.00
	--MIN SALE PRICE (PHEV): $3500.00



/**Average, max, & min Odometer_Reading at the time of purchase for USED vehicles**/
SELECT 
	FORMAT(AVG((Odometer_Reading)), 'N0') AS AVG_odometer_reading,
	FORMAT(MAX((Odometer_Reading)), 'N0') AS MAX_odometer_reading,
	FORMAT(MIN((Odometer_Reading)), 'N0') AS MIN_odometer_reading
FROM #temp_join
	WHERE New_or_Used_Vehicle = 'Used';
	--AVERAGE ODOMETER: 31,375
	--MAX ODOMETER: 293,667
	--MIN ODOMETER: 0



/**Average, max, & min Electric_Range for Electric_vehicle_type**/
SELECT 
	Electric_Vehicle_Type,
	FORMAT(AVG((Electric_Range)), 'N0') AS AVG_electric_range,
	FORMAT(MAX((Electric_Range)), 'N0') AS MAX_electric_range,
	FORMAT(MIN((Electric_Range)), 'N0') AS MIN_electric_range
FROM #temp_join
	GROUP BY Electric_Vehicle_Type;
	--AVERAGE ELECTRIC MILE RANGE (BEV): 201
	--MAX ELECTRIC MILE RANGE (BEV): 337
	--MIN ELECTRIC MILE RANGE (BEV): 29

	--AVERAGE ELECTRIC MILE RANGE (PHEV): 31
	--MAX ELECTRIC MILE RANGE (PHEV): 153
	--MIN ELECTRIC MILE RANGE (PHEV): 6



/**Yr, make, model of car with max Electric_Range by Electric_vehicle_type**/
SELECT 
	CONCAT(Model_Year,' ', Make,' ', Model) AS Yr_make_model_concat,
	Electric_Vehicle_Type,
	Electric_Range AS Max_Electric_Range
FROM #temp_join
	WHERE (Electric_Range IN (337) AND Electric_Vehicle_Type = 'Battery Electric Vehicle (BEV)')
		OR (Electric_Range IN (153) AND Electric_Vehicle_Type = 'Plug-in Hybrid Electric Vehicle (PHEV)')
	GROUP BY 
		CONCAT(Model_Year,' ', Make,' ', Model),
		Electric_Vehicle_Type,
		Electric_Range
	ORDER BY 
		Electric_Vehicle_Type,
		CONCAT(Model_Year,' ', Make,' ', Model),
		Electric_Range;
		--MAX Electric_range BEV: 2020 Tesla Model S
		--MAX Electric_range PHEV: 2021 BMW i3



/**Yr, make, model of car with min Electric_Range by Electric_vehicle_type**/
SELECT 
	CONCAT(Model_Year,' ', Make,' ', Model) AS Yr_make_model_concat,
	Electric_Vehicle_Type,
	Electric_Range AS Min_Electric_Range
FROM #temp_join
	WHERE (Electric_Range IN (29) AND Electric_Vehicle_Type = 'Battery Electric Vehicle (BEV)')
		OR (Electric_Range IN (6) AND Electric_Vehicle_Type = 'Plug-in Hybrid Electric Vehicle (PHEV)')
	GROUP BY 
		CONCAT(Model_Year,' ', Make,' ', Model),
		Electric_Vehicle_Type,
		Electric_Range
	ORDER BY 
		Electric_Vehicle_Type,
		CONCAT(Model_Year,' ', Make,' ', Model),
		Electric_Range;
		--MIN Electric_range BEV: 2019 Hyundai Ioniq
		--MIN Electric_range PHEV: 2012-2015 Toyota Prius Plug-in






---------------
/**Data exploration time pt.2!!! - results WITHOUT #temp_join table**/
/**Determining what year had the most sales**/
WITH t1 AS
	(SELECT 
		#temp_EV_title_and_reg.Transaction_year,
		COUNT(*) AS Transaction_year_total_sales
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		GROUP BY Transaction_year)

SELECT 
	Transaction_year,
	Transaction_year_total_sales,
	CONCAT(CAST(CAST((Transaction_year_total_sales*100) as decimal(11, 2))/(SELECT SUM(Transaction_year_total_sales) FROM t1) as decimal(11, 2)), '%') AS Percentage_of_total_sales_overall
FROM t1
	ORDER BY Transaction_year_total_sales DESC;
	--ANSWER: 2018 had the most transactions at 27.49%, followed by 2019 at 23.09%, then 2020 at 16.58%



/**Determining the amount of each Electric_vehicle_type purchased**/
WITH t2 AS
	(SELECT 
		#temp_EV_pop_data.Electric_vehicle_type,
		COUNT(*) AS Electric_vehicle_type_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		GROUP BY Electric_vehicle_type)

SELECT
	Electric_vehicle_type,
	Electric_vehicle_type_total,
	CONCAT(CAST(CAST((Electric_vehicle_type_total*100) as decimal(11, 2))/(SELECT SUM(Electric_vehicle_type_total) FROM t2) as decimal(11, 2)), '%') AS Percentage_of_electric_vehicle_type_total
FROM t2
	ORDER BY Electric_vehicle_type_total DESC;
	--ANSWER: Electric Vehicle (BEV) at 88.62%, followed by Plug-in Hybrid Electric Vehicle (PHEV) at 11.38%



/**Most commonly purchased Battery Electric Vehicle (BEV) considering year**/
WITH t3 AS
	(SELECT 
		CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Yr_make_model_concat,
		COUNT(*) AS Yr_make_model_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		WHERE #temp_EV_pop_data.Electric_vehicle_type = 'Battery Electric Vehicle (BEV)'
		GROUP BY CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model))

SELECT 
	Yr_make_model_concat,
	Yr_make_model_total,
	CONCAT(CAST(CAST((Yr_make_model_total*100) as decimal(11, 2))/(SELECT SUM(Yr_make_model_total) FROM t3) as decimal(11, 2)), '%') AS Percentage_of_BEV_yr_make_model_total
FROM t3
	ORDER BY Yr_make_model_total DESC;
	--ANSWER: 2018 TESLA MODEL 3 at 33.29%, followed by 2019 TESLA MODEL 3 at 15.56%, then 2020 TESLA MODEL 3 at 9.93%



/**Most commonly purchased Battery Electric Vehicle (BEV) NOT considering year**/
WITH t4 AS
	(SELECT 
		CONCAT(#temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Make_model_concat,
		COUNT(*) AS Make_model_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		WHERE #temp_EV_pop_data.Electric_vehicle_type = 'Battery Electric Vehicle (BEV)'
		GROUP BY CONCAT(#temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model))

SELECT 
	Make_model_concat,
	Make_model_total,
	CONCAT(CAST(CAST((Make_model_total*100) as decimal(11, 2))/(SELECT SUM(Make_model_total) FROM t4) as decimal(11, 2)), '%') AS Percentage_of_BEV_make_model_total
FROM t4
	ORDER BY Make_model_total DESC;
	--ANSWER: TESLA MODEL 3 at 58.79%, followed by NISSAN LEAF at 24.47%, then TESLA MODEL Y at 5.69%



/**Most commonly purchased Plug-in Hybrid Electric Vehicle (PHEV) considering year**/
WITH t5 AS
	(SELECT 
		CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Yr_make_model_concat,
		COUNT(*) AS Yr_make_model_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		WHERE #temp_EV_pop_data.Electric_vehicle_type = 'Plug-in Hybrid Electric Vehicle (PHEV)'
		GROUP BY CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model))

SELECT 
	Yr_make_model_concat,
	Yr_make_model_total,
	CONCAT(CAST(CAST((Yr_make_model_total*100) as decimal(11, 2))/(SELECT SUM(Yr_make_model_total) FROM t5) as decimal(11, 2)), '%') AS Percentage_of_PHEV_yr_make_model_total
FROM t5
	ORDER BY Yr_make_model_total DESC;
	--ANSWER: 2017 TOYOTA PRIUS PRIME at 11.19%, followed by 2023 JEEP WRANGLER at 8.62%, then 2017 CHEVROLET VOLT at 7.41%



/**Most commonly purchased Plug-in Hybrid Electric Vehicle (PHEV) NOT considering year**/
WITH t6 AS
	(SELECT 
		CONCAT(#temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Make_model_concat,
		COUNT(*) AS Make_model_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		WHERE #temp_EV_pop_data.Electric_vehicle_type = 'Plug-in Hybrid Electric Vehicle (PHEV)'
		GROUP BY CONCAT(#temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model))

SELECT 
	Make_model_concat,
	Make_model_total,
	CONCAT(CAST(CAST((Make_model_total*100) as decimal(11, 2))/(SELECT SUM(Make_model_total) FROM t6) as decimal(11, 2)), '%') AS Percentage_of_PHEV_make_model_total
FROM t6
	ORDER BY Make_model_total DESC;
	--ANSWER: TOYOTA PRIUS PRIME at 20.19%, followed by CHEVROLET VOLT at 13.30%, then JEEP WRANGLER at 13.12%



/**Most commonly purchased vehicle overall considering year**/
WITH t7 AS
	(SELECT 
		CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Yr_make_model_concat,
		#temp_EV_pop_data.Electric_vehicle_type,
		COUNT(*) AS Yr_make_model_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		GROUP BY 
			CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model),
			#temp_EV_pop_data.Electric_vehicle_type)

SELECT 
	Yr_make_model_concat,
	Electric_vehicle_type,
	Yr_make_model_total,
	CONCAT(CAST(CAST((Yr_make_model_total*100) as decimal(11, 2))/(SELECT SUM(Yr_make_model_total) FROM t7) as decimal(11, 2)), '%') AS Percentage_of_yr_make_model_total_overall
FROM t7
	ORDER BY Yr_make_model_total DESC;
	--ANSWER: 2018 TESLA MODEL 3 at 29.50%, followed by 2019 TESLA MODEL 3 at 13.79%, then 2020 TESLA MODEL 3 at 8.80%



/**Most commonly purchased vehicle overall NOT considering year**/
WITH t8 AS
	(SELECT 
		CONCAT(#temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Make_model_concat,
		#temp_EV_pop_data.Electric_vehicle_type,
		COUNT(*) AS Make_model_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		GROUP BY 
			CONCAT(#temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model),
			#temp_EV_pop_data.Electric_vehicle_type)

SELECT 
	Make_model_concat,
	Electric_vehicle_type,
	Make_model_total,
	CONCAT(CAST(CAST((Make_model_total*100) as decimal(11, 2))/(SELECT SUM(Make_model_total) FROM t8) as decimal(11, 2)), '%') AS Percentage_of_make_model_total_overall
FROM t8
	ORDER BY Make_model_total DESC;
	--ANSWER: TESLA MODEL 3 at 52.10%, followed by NISSAN LEAF at 21.69%, then TESLA MODEL Y at 5.05%



/**City in Washington that has the highest electric vehicle purchases**/
WITH t9 AS
	(SELECT 
		#temp_EV_title_and_reg.City,
		#temp_EV_title_and_reg.County,
		COUNT(*) AS City_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		GROUP BY 
			#temp_EV_title_and_reg.City,
			#temp_EV_title_and_reg.County)

SELECT
	City,
	County,
	City_total,
	CONCAT(CAST(CAST((City_total*100) as decimal(11, 2))/(SELECT SUM(City_total) FROM t9) as decimal(11, 2)), '%') AS Percentage_of_city_total
FROM t9		
	ORDER BY City_total DESC;
	--ANSWER: Seattle at 19.37%, followed by Bellevue at 6.09%, then Redmond at 4.75%



/**County in Washington that has the highest electric vehicle purchases**/
WITH t10 AS
	(SELECT 
		#temp_EV_title_and_reg.County,
		COUNT(*) AS County_total
	FROM #temp_EV_pop_data
		INNER JOIN #temp_EV_title_and_reg
			ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
		GROUP BY #temp_EV_title_and_reg.County)

SELECT
	County,
	County_total,
	CONCAT(CAST(CAST((County_total*100) as decimal(11, 2))/(SELECT SUM(County_total) FROM t10) as decimal(11, 2)), '%') AS Percentage_of_county_total
FROM t10		
	ORDER BY County_total DESC;
	--ANSWER: King at 56.41%, followed by Snohomish at 11.22%, then Pierce at 7.31%



/**Average, max, & min Sale_price for NEW vehicles per year per Electric_vehicle_type**/
SELECT 
	#temp_EV_title_and_reg.Transaction_Year,
	#temp_EV_pop_data.Electric_Vehicle_Type,
	FORMAT(AVG(CAST((#temp_EV_title_and_reg.Sale_price) as bigint)), 'C') AS AVG_sale_price,
	FORMAT(CAST(MAX((#temp_EV_title_and_reg.Sale_price)) as bigint), 'C') AS MAX_sale_price,
	FORMAT(CAST(MIN((#temp_EV_title_and_reg.Sale_price)) as bigint), 'C') AS MIN_sale_price
FROM #temp_EV_pop_data
	INNER JOIN #temp_EV_title_and_reg
		ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
	WHERE #temp_EV_title_and_reg.New_or_Used_Vehicle = 'New'
	GROUP BY 
		#temp_EV_title_and_reg.Transaction_Year,
		#temp_EV_pop_data.Electric_Vehicle_Type
	ORDER BY 
		#temp_EV_pop_data.Electric_Vehicle_Type, 
		#temp_EV_title_and_reg.Transaction_Year DESC;
	--AVERAGE SALE PRICE (BEV): 
		--highest; 2023 - $66,163.00
		--lowest; 2021 - $42,858.00
	--MAX SALE PRICE (BEV): 
		--highest; 2019 - $260,950.00
		--lowest; 2023 - $121,995.00
	--MIN SALE PRICE (BEV): 
		--highest; 2023 - $42,900.00
		--lowest; 2017, 2019-2021 - $26,000.00

	--AVERAGE SALE PRICE (PHEV): 
		--highest; 2022 - $64,645.00 
		--lowest; 2018 - $35,007.00
	--MAX SALE PRICE (PHEV): 
		--highest; 2022 - $250,440.00 
		--lowest; 2017 - $98,500.00
	--MIN SALE PRICE (PHEV): 
		--highest; 2016 - $29,255.00
		--lowest; 2017-2020 - $26,000.00



/**Average, max, & min Sale_price for USED vehicles per year per Electric_vehicle_type**/
SELECT 
	#temp_EV_title_and_reg.Transaction_Year,
	#temp_EV_pop_data.Electric_Vehicle_Type,
	FORMAT(AVG(CAST((#temp_EV_title_and_reg.Sale_price) as bigint)), 'C') AS AVG_sale_price,
	FORMAT(CAST(MAX((#temp_EV_title_and_reg.Sale_price)) as bigint), 'C') AS MAX_sale_price,
	FORMAT(CAST(MIN((#temp_EV_title_and_reg.Sale_price)) as bigint), 'C') AS MIN_sale_price
FROM #temp_EV_pop_data
	INNER JOIN #temp_EV_title_and_reg
		ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
	WHERE #temp_EV_title_and_reg.New_or_Used_Vehicle = 'Used'
	GROUP BY 
		#temp_EV_title_and_reg.Transaction_Year,
		#temp_EV_pop_data.Electric_Vehicle_Type
	ORDER BY 
		#temp_EV_pop_data.Electric_Vehicle_Type, 
		#temp_EV_title_and_reg.Transaction_Year DESC;
	--AVERAGE SALE PRICE (BEV): 
		--highest; 2022 - $38,880.00
		--lowest; 2017 - $12,554.00
	--MAX SALE PRICE (BEV): 
		--highest; 2020 - $215,590.00
		--lowest; 2016 - $99,570.00
	--MIN SALE PRICE (BEV): 
		--highest; 2016 - $5,000.00
		--lowest; 2017-2023 - $3,500.00

	--AVERAGE SALE PRICE (PHEV): 
		--highest; 2022 - $32,228.00 
		--lowest; 2019 - $19,621.00
	--MAX SALE PRICE (PHEV): 
		--highest; 2018 - $170,000.00 
		--lowest; 2017 - $99,000.00
	--MIN SALE PRICE (PHEV): 
		--highest; 2016 - $4,039.00
		--lowest; 2017, 2019, 2022-2023 - $3,500.00



/**Average, max, & min Sale_price for ALL vehicles per Electric_vehicle_type**/
SELECT 
	#temp_EV_pop_data.Electric_Vehicle_Type,
	FORMAT(AVG((#temp_EV_title_and_reg.Sale_price)), 'C') AS AVG_sale_price,
	FORMAT(MAX((#temp_EV_title_and_reg.Sale_price)), 'C') AS MAX_sale_price,
	FORMAT(MIN((#temp_EV_title_and_reg.Sale_price)), 'C') AS MIN_sale_price
FROM #temp_EV_pop_data
	INNER JOIN #temp_EV_title_and_reg
		ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
	GROUP BY #temp_EV_pop_data.Electric_Vehicle_Type;
	--AVERAGE SALE PRICE (BEV): $43,165.00
	--MAX SALE PRICE (BEV): $260,950.00
	--MIN SALE PRICE (BEV): $3500.00

	--AVERAGE SALE PRICE (PHEV): $39,806.00
	--MAX SALE PRICE (PHEV): $250,440.00
	--MIN SALE PRICE (PHEV): $3500.00



/**Average, max, & min Odometer_Reading at the time of purchase for USED vehicles**/
SELECT 
	FORMAT(AVG((#temp_EV_title_and_reg.Odometer_Reading)), 'N0') AS AVG_odometer_reading,
	FORMAT(MAX((#temp_EV_title_and_reg.Odometer_Reading)), 'N0') AS MAX_odometer_reading,
	FORMAT(MIN((#temp_EV_title_and_reg.Odometer_Reading)), 'N0') AS MIN_odometer_reading
FROM #temp_EV_pop_data
	INNER JOIN #temp_EV_title_and_reg
		ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
	WHERE #temp_EV_title_and_reg.New_or_Used_Vehicle = 'Used';
	--AVERAGE ODOMETER: 31,375
	--MAX ODOMETER: 293,667
	--MIN ODOMETER: 0



/**Average, max, & min Electric_Range for Electric_vehicle_type**/
SELECT 
	#temp_EV_pop_data.Electric_Vehicle_Type,
	FORMAT(AVG((#temp_EV_pop_data.Electric_Range)), 'N0') AS AVG_electric_range,
	FORMAT(MAX((#temp_EV_pop_data.Electric_Range)), 'N0') AS MAX_electric_range,
	FORMAT(MIN((#temp_EV_pop_data.Electric_Range)), 'N0') AS MIN_electric_range
FROM #temp_EV_pop_data
	INNER JOIN #temp_EV_title_and_reg
		ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
	GROUP BY #temp_EV_pop_data.Electric_Vehicle_Type;
	--AVERAGE ELECTRIC MILE RANGE (BEV): 201
	--MAX ELECTRIC MILE RANGE (BEV): 337
	--MIN ELECTRIC MILE RANGE (BEV): 29

	--AVERAGE ELECTRIC MILE RANGE (PHEV): 31
	--MAX ELECTRIC MILE RANGE (PHEV): 153
	--MIN ELECTRIC MILE RANGE (PHEV): 6



/**Yr, make, model of car with max Electric_Range by Electric_vehicle_type**/
SELECT 
	CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Yr_make_model_concat,
	#temp_EV_pop_data.Electric_Vehicle_Type,
	#temp_EV_pop_data.Electric_Range AS Max_Electric_Range
FROM  #temp_EV_pop_data
	INNER JOIN #temp_EV_title_and_reg
		ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
	WHERE (#temp_EV_pop_data.Electric_Range IN (337) AND Electric_Vehicle_Type = 'Battery Electric Vehicle (BEV)')
		OR (#temp_EV_pop_data.Electric_Range IN (153) AND Electric_Vehicle_Type = 'Plug-in Hybrid Electric Vehicle (PHEV)')
	GROUP BY 
		CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model),
		#temp_EV_pop_data.Electric_Vehicle_Type,
		#temp_EV_pop_data.Electric_Range
	ORDER BY 
		#temp_EV_pop_data.Electric_Vehicle_Type,
		CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model),
		#temp_EV_pop_data.Electric_Range;
		--MAX Electric_range BEV: 2020 Tesla Model S
		--MAX Electric_range PHEV: 2021 BMW i3



/**Yr, make, model of car with min Electric_Range by Electric_vehicle_type**/
SELECT 
	CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model) AS Yr_make_model_concat,
	#temp_EV_pop_data.Electric_Vehicle_Type,
	#temp_EV_pop_data.Electric_Range AS Min_Electric_Range
FROM  #temp_EV_pop_data
	INNER JOIN #temp_EV_title_and_reg
		ON #temp_EV_pop_data.VIN = #temp_EV_title_and_reg.VIN
	WHERE (#temp_EV_pop_data.Electric_Range IN (29) AND Electric_Vehicle_Type = 'Battery Electric Vehicle (BEV)')
		OR (#temp_EV_pop_data.Electric_Range IN (6) AND Electric_Vehicle_Type = 'Plug-in Hybrid Electric Vehicle (PHEV)')
	GROUP BY 
		CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model),
		#temp_EV_pop_data.Electric_Vehicle_Type,
		#temp_EV_pop_data.Electric_Range
	ORDER BY 
		#temp_EV_pop_data.Electric_Vehicle_Type,
		CONCAT(#temp_EV_pop_data.Model_Year,' ', #temp_EV_pop_data.Make,' ', #temp_EV_pop_data.Model),
		#temp_EV_pop_data.Electric_Range;
		--MIN Electric_range BEV: 2019 Hyundai Ioniq
		--MIN Electric_range PHEV: 2012-2015 Toyota Prius Plug-in


/**FIN**/