 
-- Create Table For The RFM Model
CREATE TABLE rfm  (
    Customer_ID int,
    Recency int,
    Frequency int,
    Monetary int,
	Score VARCHAR(50),
	Type VARCHAR(50)
);

-- Insert the Customers' IDs
INSERT INTO rfm 
(Customer_ID,  Recency ,
    Frequency, Monetary, Type
	)SELECT 
		DISTINCT Customer_ID, null, null, null, null
		FROM CleanData;

-- Check Max Data : 2018-08-12
SELECT 
	MAX(created_at) 
FROM CleanData;

-- Recency
WITH CTE AS(
SELECT 
	 DISTINCT Customer_ID, MAX(created_at) MaxDate
FROM CleanData
GROUP BY Customer_ID
)
UPDATE rfm 
SET Recency = DATEDIFF(
				day,MaxDate,'2018-08-12')
			FROM CTE WHERE CTE.Customer_ID  = rfm.Customer_ID;

-- Frequency
WITH CTE AS(
SELECT 
	 DISTINCT Customer_ID, COUNT(Customer_ID) Frec
FROM CleanData
GROUP BY Customer_ID
)
UPDATE rfm 
SET Frequency = Frec
			FROM CTE WHERE CTE.Customer_ID  = rfm.Customer_ID;

-- Monetary
WITH CTE AS(
SELECT 
	 DISTINCT Customer_ID, SUM(grand_total) Mone
FROM CleanData
GROUP BY Customer_ID
)
UPDATE rfm 
SET Monetary = Mone
			FROM CTE WHERE CTE.Customer_ID  = rfm.Customer_ID;

-- Recency quartiles: 219, 268, 450, 622
SELECT TOP 1
    PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY Recency) OVER() AS '1',
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY Recency) OVER() AS '5',
    PERCENTILE_CONT(0.09) WITHIN GROUP (ORDER BY Recency) OVER() AS '9',
	PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Recency) OVER() AS '20'
FROM
    rfm
	
-- Frequency quartiles: 1, 2, 3, 5 
SELECT TOP 1
    PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Frequency) OVER() AS '40',
    PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Frequency) OVER() AS '60',
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Frequency) OVER() AS '80',
	PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Frequency) OVER() AS '90'
FROM
    rfm

-- Monetary quartiles: 1300, 2988.4, 11130, 22999
SELECT TOP 1
    PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Monetary) OVER() AS '20',
    PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Monetary) OVER() AS '40',
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Monetary) OVER() AS '60',
	PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY Monetary) OVER() AS '80'
FROM
    rfm
	

-- Recency Calcolation
UPDATE rfm
	SET Score = 
			CASE
				WHEN Recency < 101 THEN '5'
				WHEN Recency >= 101 AND Recency < 134 THEN '4'
				WHEN Recency >= 134 AND Recency < 155 THEN '3'
				WHEN Recency >= 155 AND Recency < 219 THEN '2'
				ELSE '1'
			END
		FROM rfm


-- Frequency Calcolation
UPDATE rfm
	SET Score = 
			CASE
				WHEN Frequency = 1 THEN CONCAT(Score,'1')
				WHEN Frequency >= 1 AND Frequency < 2 THEN CONCAT(Score,'2')
				WHEN Frequency >= 2 AND Frequency < 3 THEN CONCAT(Score,'3')
				WHEN Frequency >= 3 AND Frequency < 5 THEN CONCAT(Score,'4')
				ELSE CONCAT(Score,'5')
			END
		FROM rfm

-- Monetary Calcolation 
UPDATE rfm
	SET Score = 
			CASE
				WHEN Monetary = 1300 THEN CONCAT(Score,'1')
				WHEN Monetary >= 1300 AND Monetary < 2988.4 THEN CONCAT(Score,'2')
				WHEN Monetary >= 2988.4 AND Monetary < 11130 THEN CONCAT(Score,'3')
				WHEN Monetary >= 11130 AND Monetary < 22999 THEN CONCAT(Score,'4')
				ELSE CONCAT(Score,'5')
			END
		FROM rfm

-- Customer Segmentation Calcolation
UPDATE rfm
	SET Type = 
			CASE
				WHEN Score  in (555, 554, 544, 545, 454, 455, 445) THEN 'Champion'
				WHEN Score  in (543, 444, 435, 355, 354, 345, 344, 335) THEN 'Loya_Customer'
				WHEN Score  in (553, 551, 552, 541, 542, 533, 532, 531, 452, 451, 442, 441, 431, 453, 433, 432, 423, 353, 352, 351, 342, 341, 333, 323) THEN 'Potential_Loyalist'
				WHEN Score  in (512, 511, 422, 421, 412, 411, 311 ) THEN 'New_Customer'
				WHEN Score  in (525, 524, 523, 522, 521, 515, 514, 513, 425,424, 413,414,415, 315, 314, 313) THEN 'Promising'
				WHEN Score  in (535, 534, 443, 434, 343, 334, 325, 324) THEN 'Need_Attention'
				WHEN Score  in (155, 154, 144, 214,215,115, 114, 113) THEN 'Cannot_Lose_Them'
				WHEN Score  in (331, 321, 312, 221, 213) THEN 'About_To_Sleep'
				WHEN Score  in (255, 254, 245, 244, 253, 252, 243, 242, 235, 234, 225, 224, 153, 152, 145, 143, 142, 135, 134, 133, 125, 124) THEN 'At_Risk'
				WHEN Score  in (332, 322, 231, 241, 251, 233, 232, 223, 222, 132, 123, 122, 212, 211) THEN 'Hibernating'
				WHEN Score  in (111, 112, 121, 131, 141, 151) THEN 'Lost'
			END
		FROM rfm



-- Final Check
SELECT * FROM rfm
