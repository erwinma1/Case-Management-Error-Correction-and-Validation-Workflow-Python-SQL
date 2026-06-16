
/*
SQL Law Manager Query for DOCKET/INDICTMENT Number Matches

This is a query that retrieves 'No Next Court Date' cases for data cleaning and hygiene puproses.
Without the next court date, attorneys calendars are not reflecting the proper schedule.
These fields should be cross referenced with UCE, NYCIS, or Webcrims, and be entered and corrected in Law Manager.

Test logic for consistency

For questions contact ema@legal-aid.org
*/

SELECT a.matter_key, a.docket_number,a.indictment_number, a.county, a.las_practice_office_name, a.arrest_number, a.NYSID, a.client_intake_name, a.date_opened,
b.appear_date as 'latest_appear_date', b.court_part, b.next_court_date,
c.uce_latest_appear_date,c.uce_appearance_part, c.uce_appearance_outcome, c.uce_docket_dispo_category, c.uce_docket_dispo_reason,
a.matter_stage,e.active_case_count, d.consolidate_indictment,  f.description as 'LM_description',
CASE 
WHEN a.docket_number LIKE '%FG%' AND a.matter_stage = 'TR-SCt [Pending Dispo]' THEN 'Check UCE/NYCIS for SFG docket'
WHEN a.docket_number LIKE 'MZ%' THEN 'MZ Docket: Use TR-PRDU in appearance action'
WHEN c.uce_docket_dispo_category in ('Dismissals', 'Guilty Pleas') THEN 'UCE Disposed: Check Final Dispo/Covered/NYCIS'
WHEN b.appear_date > c.uce_latest_appear_date THEN 'UCE Outdated: Need more info - Check NYCIS'
WHEN b.appear_date < c.uce_latest_appear_date AND c.uce_latest_appear_date >= GETDATE() AND CAST(e.active_case_count AS INT) > 0 AND d.consolidate_indictment is not NULL THEN 'UCE Updated: Active case - use UCE date/check IND consolidation'
WHEN b.appear_date < c.uce_latest_appear_date AND c.uce_latest_appear_date >= GETDATE() AND CAST(e.active_case_count AS INT) = 0 AND d.consolidate_indictment is NULL THEN 'UCE Updated: Active case - use UCE date'
WHEN b.appear_date < c.uce_latest_appear_date AND c.uce_latest_appear_date >= GETDATE() THEN 'UCE Updated: Active case - use UCE date'
WHEN b.appear_date < c.uce_latest_appear_date AND c.uce_latest_appear_date < GETDATE() THEN 'UCE Updated: Need more info - Check Dispo/NYCIS/IND Consolidate'
WHEN b.appear_date = c.uce_latest_appear_date AND e.active_case_count > 0  THEN 'LM-UCE Aligned: Need more info - check IND consolidation and Calendar/ NYCIS'
WHEN b.appear_date = c.uce_latest_appear_date AND e.active_case_count = 0 THEN 'LM-UCE Aligned: Need more info - check Calendar/ NYCIS'
WHEN b.next_court_date > c.uce_latest_appear_date THEN 'UCE Outdated: Need more info - check Calendar/NYCIS'
WHEN b.next_court_date < c.uce_latest_appear_date  AND c.uce_latest_appear_date >= GETDATE() AND CAST(e.active_case_count AS INT) > 0 AND d.consolidate_indictment is not NULL THEN 'UCE Updated: Active case - use UCE date/check IND consolidation'
WHEN b.next_court_date < c.uce_latest_appear_date  AND c.uce_latest_appear_date >= GETDATE() AND CAST(e.active_case_count AS INT) = 0 AND d.consolidate_indictment is NULL THEN 'UCE Updated: Active case - use UCE date'
WHEN b.next_court_date < c.uce_latest_appear_date  AND c.uce_latest_appear_date >= GETDATE() THEN 'UCE Updated: Active case - use UCE date'
WHEN b.next_court_date < c.uce_latest_appear_date  AND c.uce_latest_appear_date < GETDATE() THEN 'UCE Updated: Need more info - Check Dispo/NYCIS/IND Consolidate'
WHEN b.next_court_date = c.uce_latest_appear_date AND e.active_case_count > 0 THEN 'LM-UCE Aligned: Need more info - check IND consolidation and Calendar/ NYCIS'
WHEN b.next_court_date = c.uce_latest_appear_date AND e.active_case_count = 0 THEN 'LM-UCE Aligned: Need more info - check Calendar/ NYCIS'
WHEN uce_latest_appear_date is null THEN 'No UCE Record: Need more info - Check Calendar/ NYCIS'
END AS 'Recommended_Checks'
FROM 
(
--matter table
SELECT DISTINCT 
m.matter_key, m.docket_number, m.indictment_number, m.county, po.las_practice_office_name, m.arrest_number, m.client_nysid_nbr as 'NYSID', m.client_intake_name, m.date_opened,
ms.description as 'matter_stage'
FROM matter m
LEFT JOIN LASPracticeOffice po on po.las_practice_office_key = m.orig_las_practice_office_key
LEFT JOIN MatterStage ms on ms.matter_stage_key = m.matter_stage_key
WHERE 
m.orig_las_practice_office_key in (8,9,10,11,53) -- criminal trials bx,mn,qn,bk,si
--and m.date_opened >= '2005-01-01' -- date range, usually search for newer cases. 
and m.next_court_date is NULL -- empty NCD
and m.status_flag != 'C' -- status = not closed
and m.final_case_dispo_key is Null
and m.matter_type_key = 14 -- case type = criminal trials 
)a
--LM case appearances
LEFT JOIN (
SELECT cca.matter_key, cca.appear_date, cca.court_part, cca.next_court_date
	FROM(
		SELECT DISTINCT ca.matter_key, ca.start_date as 'appear_date', ca.next_court_date, cp.description as 'court_part',
			ROW_NUMBER() OVER(
			PARTITION BY ca.matter_key
			ORDER BY ca.start_date DESC
			)as 'appear_rank'
		FROM CaseAppearance ca
		LEFT JOIN courtpart cp on cp.court_part_key = ca.court_part_key
	)cca 
		WHERE cca.appear_rank = 1
)b on b.matter_key = a.matter_key
--UCE Appearances
LEFT JOIN (
	SELECT DISTINCT uu.matter_key, uu.uce_appearance_outcome, uu.uce_appearance_date as 'uce_latest_appear_date', uu.uce_docket_dispo_category, uu.uce_docket_dispo_reason, uu.appear_rank, uu.uce_appearance_part
	FROM(
		SELECT DISTINCT u.matter_key, u.uce_appearance_outcome, u.uce_appearance_date, u.uce_docket_dispo_category, u.uce_appearance_part, u.uce_docket_dispo_reason,
			ROW_NUMBER() OVER(
			PARTITION BY u.matter_key
			ORDER BY u.uce_appearance_date DESC
			)as 'appear_rank'
		FROM UceAppearances u 
		)uu
	WHERE uu.appear_rank = 1
)c on c.matter_key = a.matter_key
--Get the active indictment, possible consolidation
LEFT JOIN(
SELECT m2.client_nysid_nbr, m2.indictment_number as 'consolidate_indictment'
FROM (
	SELECT m.client_nysid_nbr, m.indictment_number,
		ROW_NUMBER() OVER(
		PARTITION BY m.client_nysid_nbr
		ORDER BY m.date_opened DESC
			)as 'indictment_rank'
FROM Matter m
WHERE m.status_flag != 'C' 
AND m.indictment_number LIKE 'IND%' 
AND m.client_nysid_nbr != 'DUP'
AND m.client_nysid_nbr not LIKE 'No%'
)m2
WHERE m2.indictment_rank = 1
)d on d.client_nysid_nbr = a.NYSID
--Get active case count
LEFT JOIN(
	SELECT m.client_nysid_nbr, CAST(COUNT(DISTINCT m.matter_key)as INT)-1 as 'active_case_count'
	FROM matter m
	WHERE m.status_flag != 'C' 
	AND m.final_case_dispo_key is Null
	AND m.client_nysid_nbr != 'DUP'
	AND m.client_nysid_nbr not LIKE 'No%'
	GROUP BY m.client_nysid_nbr
)e on e.client_nysid_nbr = a.NYSID
--Get Matter Description
LEFT JOIN(
	SELECT m.matter_key, m.description 
	FROM matter m 
	WHERE m.description is not NULL
	)f on f.matter_key = a.matter_key
-- Super Query Additional Filters
WHERE b.appear_date <= GETDATE() -- don't use next_court_date because it will exclude null values
ORDER BY county, Recommended_Checks, latest_appear_date, matter_key