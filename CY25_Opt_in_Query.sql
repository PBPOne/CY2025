with PBP as (
select PartnerCode, sum(AddonCoins) as PBP_Coins, 0 as Contest_Coins  FROM [PBPOneDB].[dbo].[PartnerQuarterlyCalculation]
WHERE IsActive=1 and Quarter <> 'Q1'
group by PartnerCode
),
Contests as
(
select PartnerCode, 0 as PBP_Coins,sum(TotalCoinsEarned) as Contest_Coins from [PBPOneDB].[dbo].ContestCoinsCalculation 
where IsActive =1 and TotalCoinsEarned > 0  and Year = 2025
group by  PartnerCode
),
Coins_total as
(
select *  from PBP 
union all 
select *  from Contests
),
Coins_total_grouped as
(
select PartnerCode, sum(PBP_Coins) as PBP_Coins, sum(Contest_Coins) as Contest_Coins   from Coins_total
group by PartnerCode
),
Redemption as
(
select PartnerCode, sum(TotalRedeem) as TotalRedeem from [PBPOneDB].[dbo].[RedemptionSummary]
group by PartnerCode
),
Balance as
(
select p.*,
isnull(TotalRedeem,0) as TotalRedeem,
floor(PBP_Coins + Contest_Coins- isnull(TotalRedeem,0)) as Balance_Coins
from Coins_total_grouped p
left join Redemption r
on p.PartnerCode= r.PartnerCode
),
Annual as
(
select PartnerCode, AnnualTier,AnnualTierLevel,WeightedNet from [PBPOneDB].[dbo].AnnualCalculations
where IsActive=1
and WeightedNet >= 4000000
),
opt_in_final as
(
select  
b.*, a.AnnualTier, a.WeightedNet,
case when a.AnnualTierLevel = 2 and a.WeightedNet >= 15000000 and Balance_Coins >= 150000 then 'One Club'
	 when a.AnnualTierLevel = 1 and WeightedNet >= 8000000 and Balance_Coins >= 80000 then 'CBO'
	 when a.AnnualTierLevel = 0 and WeightedNet >= 4000000 and Balance_Coins >= 40000 then 'Masters'
	 else null
	 end as 'Next Club'
from Balance b
join Annual a on b.PartnerCode = a.PartnerCode
where Balance_Coins >= 40000
)
select * from opt_in_final
where [Next Club] is not null

--and PartnerCode = 'IP383217'
--order by Balance_Coins desc
--select * from Balance where Balance_Coins >= 39900







