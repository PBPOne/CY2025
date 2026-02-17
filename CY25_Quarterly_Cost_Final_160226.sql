--Quarterly Cost Calculation
select PartnerCode, Quarter,Tier,
WeightedNet, Motor_WNet, Health_WNet, Life_WNet,SME_WNet,
AddonCoins, Motor_AddonCoins, Health_AddonCoins, Life_AddonCoins, SME_AddonCoins,
FixedCoins, Motor_FixedCoins, Health_FixedCoins, Life_FixedCoins, SME_FixedCoins
from PBPOneDB.dbo.PartnerQuarterlyCalculation (nolock)
where Quarter <> 'Q1' and TierLevel > 0 
and IsActive=1

