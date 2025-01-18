WITH tb_rfm AS (
    SELECT customer_id,
        RECENCY = DATEDIFF(DAY, MAX(transaction_date), '2018-12-31'),
        FREQUENCY = COUNT(DISTINCT(order_id)),
        MONETARY = SUM(CAST(final_price AS BIGINT))
    FROM (SELECT * FROM payment_history_17
        UNION ALL 
        SELECT * FROM payment_history_18) AS tb_data
    WHERE message_id = 1
    GROUP BY customer_id
)
, tb_score AS (
SELECT *
    , PERCENT_RANK() OVER (ORDER BY RECENCY) AS r_score 
    , PERCENT_RANK() OVER (ORDER BY FREQUENCY DESC) AS f_score
    , PERCENT_RANK() OVER (ORDER BY MONETARY DESC) AS m_score
FROM tb_rfm 
)
, tb_rank AS (
SELECT *,
CASE 
    WHEN r_score <= 0.25 THEN 1
    WHEN r_score <= 0.5 THEN 2
    WHEN r_score <= 0.75 THEN 3
    ELSE 4 END AS r_rank,
CASE 
    WHEN f_score <= 0.25 THEN 1
    WHEN f_score <= 0.5 THEN 2
    WHEN f_score <= 0.75 THEN 3
    ELSE 4 END AS f_rank,
CASE 
    WHEN m_score <= 0.25 THEN 1
    WHEN m_score <= 0.5 THEN 2
    WHEN m_score <= 0.75 THEN 3
    ELSE 4 END AS m_rank
FROM tb_score 
)
SELECT *, 
    CASE 
        WHEN CONCAT(r_rank, f_rank, m_rank) IN ('111', '112', '121', '122', '211', '212', '221') THEN 'VIP Customers'
        WHEN CONCAT(r_rank, f_rank, m_rank) IN ('113', '114', '123', '124', '213', '214', '222', '223', '224', '311', '312', '313', '314') THEN 'Loyal Customers'
        WHEN CONCAT(r_rank, f_rank, m_rank) IN ('131', '132', '133', '134', '141', '142', '231', '321', '322', '323', '324', '411', '412', '421', '422') THEN 'Potential Customers'
        WHEN CONCAT(r_rank, f_rank, m_rank) IN ('143', '144', '232', '233', '234', '241', '242','243', '244') THEN 'New Customers'
        ELSE 'Lost Customers' END AS Segmentation
FROM tb_rank 
