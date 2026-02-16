with dates as 
			(select '2025-10-01' as min_date, 
					'2026-01-01' as max_date),
spl_deals as
(
	select 
		[MatrixLeadId], product from [TestDB].[dbo].[tbl_ContestDB] t
	cross join dates d
		where
		product <> 'Health_taken'
		and t.ContestMonth >= d.min_date
),
motor_dealers as
	(select 
		concat('IP',AffiliateID) as AffiliateID 
	from [PospDB].[dbo].AffiliateCohort
),
all_bookings_1 as --bp
(
select b1.LEADID, PlanId, SupplierId, ProductID from [PospDB].[dbo].BookingDetails_v1 b1 (nolock)
),
all_bookings_2 as --sumis
(
select 
	LEADID, SumInsured,ProductID 
from [PospDB].[dbo].BookingDetails_v1 (nolock)
		where ProductID in ('3','106','118','130','138','144','189','190','147','224')
),
life_plans as --pl
(
select 
	distinct PlanID,ProductID,SupplierID,PayoutProdCat 
from [PospDB].insurers.life_plan_details (nolock)
	where not (PlanID = '10583' and PayoutProdCat = 'ULIP')
),
all_bookings as --vw
(
	select 
		vw.Utm_term,vw.leadid,vw.TotalPremium,vw.ProductId,IsComplianceN,
		vw.[Insurer Name],vw.PlanName,vw.PaymentPeriodicity,vw.BookingMode,vw.BookingDate,
		vw.BusinessType, vw.SubProduct,vw.VehicleSubClass,

	case when vw.ProductId in ('3','106','118','130','138','144','189','190','147','224')		
	    and vw.BookingDate < '2025-09-22'  
		then round(convert(float,vw.APE)/1.18,0)

		when vw.ProductId in ('3','106','118','130','138','144','189','190','147','224')
		and vw.BookingDate >= '2025-09-22'
		THEN VW.APE
		when vw.ProductId in ('7','115','200') and vw.BookingDate >= '2025-09-22' and vw.Utm_term not in ('IP100159','IP100179','IP105525','IP115619','IP124010','IP127691','IP13238','IP134110','IP141465','IP147548','IP148617','IP15273','IP153865','IP156521','IP164237','IP170176','IP177435','IP178895','IP183331','IP192588','IP195531','IP199751','IP209687','IP219216','IP231073','IP236997','IP242099','IP242489','IP248199','IP252398','IP255302','IP258125','IP264310','IP265449','IP269013','IP269774','IP278250','IP283095','IP283286','IP283432','IP287600','IP292092','IP294363','IP296959','IP302282','IP305165','IP326849','IP343502','IP353269','IP353466','IP368349','IP383217','IP3862','IP392901','IP41262','IP9278','IP97596')
		then ab.life_pr
		when vw.Utm_term in ('IP100159','IP100179','IP105525','IP115619','IP124010','IP127691','IP13238','IP134110','IP141465','IP147548','IP148617','IP15273','IP153865','IP156521','IP164237','IP170176','IP177435','IP178895','IP183331','IP192588','IP195531','IP199751','IP209687','IP219216','IP231073','IP236997','IP242099','IP242489','IP248199','IP252398','IP255302','IP258125','IP264310','IP265449','IP269013','IP269774','IP278250','IP283095','IP283286','IP283432','IP287600','IP292092','IP294363','IP296959','IP302282','IP305165','IP326849','IP343502','IP353269','IP353466','IP368349','IP383217','IP3862','IP392901','IP41262','IP9278','IP97596')
		then vw.APE
		else vw.[Net Premium] end as netpr,
	case when vw.ODTerm >=1 and vw.TPTerm >= 5 then 'TWN' 
			when vw.ODTerm >=1 and vw.TPTerm>=1 then 'comp'
			when vw.ODTerm = 0 and vw.TPTerm>=1 then 'tp'
			when vw.ODTerm >=1 and vw.TPTerm = 0 then 'saod'
			else 'NA' end AS plan_type,
	case when vw.BusinessType in ('Fresh Booking','New','Fresh','NEW BUSINESS') then 'Fresh' 
			when vw.BusinessType in ('Fresh Port','New Port') then 'Port'	--'New Port' added
			else vw.BusinessType end as BT					
from [PospDB].[dbo].vwAllBookingDetails vw (nolock)
	left join (select LEADID,isnull(BasicPremium,0) as life_pr from PospDB.dbo.BookingDetails_v1 (nolock)) as ab
	on vw.leadid = ab.LEADID
	join (select StatusId, StatusMode from [PospDB].[dbo].StatusMaster (nolock) where StatusMode = 'P' and StatusId not in ('56','76','82')) st
	--56-Registration, 76-Retention, 82-Reopen
	on vw.StatusId = st.StatusId
	cross join dates d
	where
	vw.BookingDate >= d.min_date
	and vw.BookingDate < d.max_date
),
t1 as
(
select 
	vw.*, bp.PlanId,pl.PayoutProdCat,sumis.SumInsured,
	case when vw.ProductId in (186) and vw.SubProduct = 'Taxi' then 188 
		when vw.ProductId in ('186') and vw.SubProduct is null and vw.VehicleSubClass = 'Taxi' then 188
		when vw.ProductId in ('190') 
			and bp.PlanId in 
					('162','315','116','221','121','260','271','172','232','132',
					'446','468','521','564','15658','15774','46549','144','245',
					'246','247','248','249','323','324','325','661','662','38121',
					'80973','81030','81336','164','215','216','224','115','273','233',
					'236','36','127','128','131','129','130','386','372','455','577',
					'534','563','12368','12426','15659','20028','20243','32689','209',
					'218','305','306','307','311','312','313','316','317','55464','55466',
					'81330','81362','161','9','318','148','67','136','137','350','426','427',
					'432','433','464','503','518','519','538','617','622','625','644','649',
					'11083','15648','15773','15861','32691','143','351','352','353','414',
					'415','442','558','559','560','9022','43231','55467')
		then 1900 
		else vw.ProductId end as product_updated
	
from all_bookings vw
	join all_bookings_1 bp on vw.leadid = bp.LEADID
	left join life_plans pl on bp.PlanId = pl.PlanID and bp.ProductID = pl.ProductID and bp.SupplierId = pl.SupplierID
	left join all_bookings_2 sumis on vw.leadid = sumis.LEADID and vw.ProductId = sumis.ProductID
	where				
	vw.ProductId in ('107','186','187','188') --Motor
	and vw.leadid not in (select MatrixLeadId from spl_deals where product='Motor') 
	or(
	vw.ProductId in ('131','193','194','221') --SME
	and vw.leadid not in (select MatrixLeadId from spl_deals where product='SME'))
	or (
	vw.ProductId in ('3','106','118','130','138','144','189','190','147','224') --Health
	and vw.BusinessType in ('Fresh Booking','New','NEW BUSINESS','Fresh','Fresh Port','New Port') --'New Port' added
	and vw.leadid not in (select MatrixLeadId from spl_deals where product='Health')) 
	or (
	vw.ProductId in ('7','115','200')  --Life
	and vw.BusinessType in ('Fresh Booking','New','NEW BUSINESS','Fresh')
	and vw.leadid not in (select MatrixLeadId from spl_deals where product='Life'))			   
	),

p0 as 
		(select 
			PartnerCode, null as Marking 
		from [PospDB].[dbo].vwAllPartnerDetails_v1  (nolock)
			where 
				PartnerCode like 'IP%'
				and SellNowEnabled = 'Yes' 
				and ComplianceCertified = 'Yes'
				and SalesCat <> 'prime'
		),
p00 as
(
select 
			PartnerCode,'Life_NC' as Marking
		from [PospDB].[dbo].vwAllPartnerDetails_v1  (nolock)
			where 
				PartnerCode like 'IP%'
				and ((SalesCat in ('VRM') and NH_NAME in ('VRMs Life')) or SalesCat in ('Life'))
				and (ComplianceCertified = 'No' or SellNowEnabled = 'No')
				and SalesCat <> 'prime'
),

p00s as
(
select 
			PartnerCode,'Life_NC' as Marking
		from [PospDB].[dbo].vwAllPartnerDetails_v1  (nolock)
			where 
				(PartnerCode like 'IP%'
				and  SalesCat in ('SME')
				and (ComplianceCertified = 'No' or SellNowEnabled = 'No')
				and SalesCat <> 'prime')
				or 
				PartnerCode in 

				('IP165945','IP214251','IP379325','IP164070','IP224017','IP122618','IP290393','IP261305','IP332315','IP115100','IP232014','IP268411','IP366164','IP228903','IP380100','IP49038','IP201528','IP333920')
),

p1 as
(
select * from p0
union all
select * from p00
union all
select * from p00s
),
tr as	
	(select * from t1 
		join  p1 
		on t1.Utm_term = p1.PartnerCode
	), 
tr1 as 
	(select 
		tr.PartnerCode,tr.leadid, TotalPremium as Total_pr,tr.netpr,IsComplianceN,Marking, --SalesCat,  NH_NAME,
		plan_type,	BookingMode,	BT,	SumInsured,	BusinessType,	SubProduct,	VehicleSubClass,PaymentPeriodicity,	
		product_updated,	PlanName,PayoutProdCat,[Insurer Name],
		DATEFROMPARTS(YEAR(BookingDate), MONTH(BookingDate), 1) as MON1,
		case 
			when tr.ProductId in ('3','106','118','130','138','144','189','190','147','224') then 'Health' 
			when tr.ProductId in ('7','115','200') then 'Life' 
			when tr.ProductId in ('107','186','187','188') then 'Motor'
			when tr.ProductId in ('131','193','194','221') then 'SME' ELSE 'Other' end as product,
		case
			when tr.[Insurer Name] in ('LIC India') then 0-- Added on 11 Dec 25
			when tr.ProductId in ('115','200') and tr.PayoutProdCat = 'ULIP' then 0
			when tr.ProductId in ('7','115','200') 
				and tr.PaymentPeriodicity in ('Single','Single pay','Single Premium') 
				and tr.[Insurer Name] not in ('LIC India') then tr.netpr*0.1
			--when tr.ProductId in ('7','115','200') 
				--and tr.PaymentPeriodicity in ('Single','Single pay','Single Premium') 
				--and tr.[Insurer Name] in ('LIC India') then 0
			
			when tr.product_updated in ('3','118','189','130','147','1900','224') then tr.netpr*1.25   ---added '3-travel' 

			when tr.product_updated in ('106','138','144','190')
			and tr.BT = 'Fresh' and tr.SumInsured >= 2000000 then tr.netpr*1.25

			when tr.product_updated in ('106','138','144','190')
			and tr.BT = 'Fresh' 
			and tr.SumInsured >= 1000000 and tr.SumInsured <2000000 then tr.netpr*1.15

			when tr.product_updated in ('106','138','144','190')
			and tr.BT = 'Fresh' 
			and tr.SumInsured >= 500000 and tr.SumInsured < 1000000 then tr.netpr

			when tr.product_updated in ('106','138','144','190') 
			and tr.BT = 'Fresh' 
			and tr.SumInsured > 0 and tr.SumInsured < 500000 then tr.netpr*0.25

			--when tr.product_updated in ('106','138','144','190')
			--and tr.PlanId in ('49156','49157','49158','9929','9096')
			--and tr.BT = 'Port' 
			--then tr.netpr*0.75   --port friendly

			when tr.product_updated in ('106','138','144','190')
			and tr.BT = 'Port' 
			and tr.SumInsured >= 1000000 then tr.netpr*0.75

			when tr.product_updated in ('106','138','144','190')
			--and tr.PlanId not in ('49156','49157','49158','9929','9096')
			and tr.BT = 'Port' 
			and tr.SumInsured < 1000000 then 0 

			  when tr.product_updated in ('186') 
				and tr.plan_type in ('comp','saod') 
				and tr.BookingMode = 'Online' then tr.netpr*1.1
			  when tr.product_updated in ('186') 
				and tr.plan_type in ('comp','saod','tp') 
				and tr.BookingMode = 'Offline' then tr.netpr*0.9
			  when tr.product_updated in ('187') 
				and tr.plan_type in ('comp','saod','tp') 
				and tr.BookingMode = 'Offline' then 0
			  when tr.product_updated in ('187') 
				and tr.plan_type in ('TWN') 
				and tr.BookingMode = 'Online' then tr.netpr*1
			  when tr.product_updated in ('187') 
				and tr.plan_type in ('TWN') 
				and tr.BookingMode = 'Offline' then tr.netpr*0.9
			  when tr.ProductId in ('131','193','194') 
				and tr.PlanName = 'Group Gratuity Plan' then tr.netpr*0.1
			  when tr.product_updated in ('131','193','194') 
				and tr.PlanName != 'Group Gratuity Plan' 
				and tr.PlanName like '%Group%' then tr.netpr*0.25
			  when tr.product_updated in ('131','193','194') 
				and tr.PlanName not like '%Group%' then tr.netpr*1.25 
			  else tr.netpr end as Accrual_Net
			 
	from tr 
		)
select top 10
	PartnerCode,leadid,Product,MON1,Total_pr,netpr,Accrual_Net,
	plan_type,BookingMode,BT,[Insurer Name],SumInsured, BusinessType,SubProduct, VehicleSubClass,
	product_updated, PlanName, PaymentPeriodicity,PayoutProdCat,IsComplianceN

	from tr1 --where IsComplianceN= 'yes' --and product= 'Motor' --and  PartnerCode= 'IP108088' 

