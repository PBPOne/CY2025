with cte as
(
select PartnerCode,AnnualTier from PBPOneDB.dbo.AnnualCalculations
where IsActive=1 
AND AnnualTierLevel >0 
)
select  
q.PartnerCode, a.AnnualTier,
sum(case when Quarter = 'Q1' then WeightedNet*.8 else WeightedNet end) as WeightedNet,
sum(case when Quarter = 'Q1' then Motor_WNet*.8 else Motor_WNet end) as Motor_WNet,
sum(case when Quarter = 'Q1' then Health_WNet*.8 else Health_WNet end) as Health_WNet,
sum(case when Quarter = 'Q1' then Life_WNet*.8 else Life_WNet end) as Life_WNet,
sum(case when Quarter = 'Q1' then SME_WNet*.8 else SME_WNet end) as SME_WNet

from PBPOneDB.dbo.PartnerQuarterlyCalculation q
join cte a
on q.PartnerCode = a.PartnerCode
group by q.PartnerCode, a.AnnualTier

--IP99306

--select * from PBPOneDB.dbo.RedemptionSummary