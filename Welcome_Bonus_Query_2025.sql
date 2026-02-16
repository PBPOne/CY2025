WITH dates AS (
    SELECT 
        CAST('2025-07-01' AS DATE) AS min_date, 
        CAST('2026-01-01' AS DATE) AS max_date
),

NOC_Partners AS (
    SELECT 'IP' + CAST(AffiliateID AS VARCHAR(10)) AS PartnerCode 
    FROM PospDB.dbo.Resignationdetails WITH (NOLOCK)
    WHERE NocIssuedOn IS NOT NULL
),

new_partners AS (
    SELECT
        ar.AffiliateCode AS PartnerCode,
        CAST(av.SellNowDate AS DATE) AS SellNowDate,
        DATEFROMPARTS(YEAR(av.SellNowDate), MONTH(av.SellNowDate), 1) AS SellNowMonth
    FROM PospDB.dbo.Affiliate_Verification av WITH (NOLOCK)
    JOIN PospDB.dbo.Affiliate_Registration ar WITH (NOLOCK)
        ON av.AffiliateId = ar.ID
    CROSS JOIN dates d
    WHERE SellNowDate IS NOT NULL
      AND SellNowDate >= d.min_date
      AND SellNowDate < d.max_date
      AND AffiliateCode LIKE 'IP%'
      AND NOT EXISTS (
            SELECT 1 FROM PospDB.dbo.vwAllPartnerDetails_v1 p WITH (NOLOCK)
            WHERE p.PartnerCode = ar.AffiliateCode AND p.SalesCat = 'prime'
      )
      AND NOT EXISTS (
            SELECT 1 FROM PospDB.dbo.AffiliateCohort ac WITH (NOLOCK)
            WHERE ac.AffiliateID = REPLACE(ar.AffiliateCode,'IP','')
      )
      AND NOT EXISTS (
            SELECT 1 FROM NOC_Partners np WHERE np.PartnerCode = ar.AffiliateCode
      )
),



eligible_partners_1 AS (
    SELECT 
        ab.Utm_term,
        MIN(ab.BookingDate) AS first_booking_date,
        DATEFROMPARTS(YEAR(ab.BookingDate), MONTH(ab.BookingDate), 1) AS booking_month,
        SUM(ab.[Net Premium]) AS monthly_net_premium
    FROM PospDB.dbo.vwAllBookingDetails ab WITH (NOLOCK)
    JOIN PospDB.dbo.StatusMaster sm WITH (NOLOCK)
        ON ab.StatusId = sm.StatusId AND sm.StatusId NOT IN ('56','76','82')
    CROSS JOIN dates d
    WHERE ab.Utm_term LIKE 'IP%' --and ab.BookingDate >= '2025-07-01'
      AND NOT EXISTS (
            SELECT 1 FROM TestDB.dbo.tbl_ContestDB c WITH (NOLOCK)
            WHERE c.MatrixLeadId = ab.LeadId
              AND c.ContestMonth >= d.min_date
      )
    GROUP BY ab.Utm_term, DATEFROMPARTS(YEAR(ab.BookingDate), MONTH(ab.BookingDate), 1)
),

--select top 5 * from eligible_partners_1

eligible_partners_2 AS (
    SELECT 
        ep1.Utm_term,
        --np.SellNowDate,
        ep1.booking_month,
        ep1.monthly_net_premium,
        CASE WHEN ep1.first_booking_date < np.SellNowDate THEN 0 ELSE 1 END AS eligibility
    FROM eligible_partners_1 ep1
    JOIN new_partners np
        ON np.PartnerCode = ep1.Utm_term 
       AND np.SellNowMonth = ep1.booking_month
),

eligible_partners_3 AS (
    SELECT 
        Utm_term,
        --SellNowDate,
        booking_month AS first_booking_month,
        monthly_net_premium AS first_month_net_pr
    FROM eligible_partners_2
    WHERE eligibility = 1
      AND monthly_net_premium >= 10000
),

eligible_partners_final AS (
    SELECT 
        np.PartnerCode,
        np.SellNowDate,
        ep.first_booking_month,
        ep.first_month_net_pr
    FROM new_partners np
    JOIN eligible_partners_3 ep
        ON np.PartnerCode = ep.Utm_term 
       AND np.SellNowMonth = ep.first_booking_month
)

SELECT  *
FROM eligible_partners_final;