WITH base AS (
    -- 1. Sessions (for counting accounts connected to email newsletters)
    SELECT
        s.date AS datee,
        sp.country,
        ac.send_interval AS sent_intervall,
        ac.is_verified,
        ac.is_unsubscribed,
        COUNT(DISTINCT acs.account_id) AS account_cnt,
        0 AS em_sent_cnt,
        0 AS em_open_cnt,
        0 AS em_visit_cnt
    FROM
        `DA.session` AS s
    INNER JOIN `DA.session_params` AS sp ON s.ga_session_id = sp.ga_session_id
    INNER JOIN `DA.account_session` AS acs ON sp.ga_session_id = acs.ga_session_id
    INNER JOIN `DA.account` AS ac ON acs.account_id = ac.id
    INNER JOIN `DA.email_sent` AS es ON ac.id = es.id_account
    GROUP BY 1, 2, 3, 4, 5
    UNION ALL
    -- 2. Email Metrics
    SELECT
        ss.date AS datee,
        sp.country,
        acc.send_interval AS sent_intervall,
        acc.is_verified,
        acc.is_unsubscribed,
        0 AS account_cnt,
        COUNT(DISTINCT es.id_message) AS em_sent_cnt,
        COUNT(DISTINCT eo.id_message) AS em_open_cnt,
        COUNT(DISTINCT ev.id_message) AS em_visit_cnt
    FROM
        `DA.email_sent` AS es
    LEFT JOIN `DA.email_open` AS eo ON es.id_message = eo.id_message
    LEFT JOIN `DA.email_visit` AS ev ON es.id_message = ev.id_message
    INNER JOIN `DA.account` AS acc ON es.id_account = acc.id
    INNER JOIN `DA.account_session` AS acs ON acc.id = acs.account_id
    INNER JOIN `DA.session_params` AS sp ON acs.ga_session_id = sp.ga_session_id
    INNER JOIN `DA.session` AS ss ON sp.ga_session_id = ss.ga_session_id
    GROUP BY 1, 2, 3, 4, 5
),
--Aggregation of email metrics and accounts by all dimensions
agregations AS (
    SELECT
        datee,
        country,
        sent_intervall,
        is_verified,
        is_unsubscribed,
        SUM(account_cnt) AS total_account_cnt,
        SUM(em_sent_cnt) AS sent_msg,
        SUM(em_open_cnt) AS open_msg,
        SUM(em_visit_cnt) AS visit_msg
    FROM
        base
    GROUP BY 1, 2, 3, 4, 5
),
-- Calculation of general indicators by country
totals AS (
    SELECT
        agg.datee,
        agg.country,
        agg.sent_intervall,
        agg.is_verified,
        agg.is_unsubscribed,
        agg.total_account_cnt AS account_cnt, 
        agg.open_msg,
        agg.sent_msg,
        agg.visit_msg,
        SUM(agg.total_account_cnt) OVER(PARTITION BY agg.country) AS total_country_account_cnt,
        SUM(agg.sent_msg) OVER(PARTITION BY agg.country) AS total_country_sent_cnt
    FROM
        agregations AS agg
),
-- Ranking of countries
ranks AS (
    SELECT
        *,
        DENSE_RANK() OVER(
            ORDER BY total_country_account_cnt DESC
        ) AS rank_total_country_account_cnt,
        DENSE_RANK() OVER(
            ORDER BY total_country_sent_cnt DESC
        ) AS rank_total_country_sent_cnt
    FROM
        totals
)
SELECT *
FROM ranks
WHERE
    rank_total_country_account_cnt <= 10 OR rank_total_country_sent_cnt <= 10






