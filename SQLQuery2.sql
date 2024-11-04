-- TOTAL SEAT
SELECT COUNT(parliament_constituency) AS TOTAL_SEAT
FROM statewise_results

-- WHAT IS THE TOTAL NUMBER OF SEATS AVAILABLE FOR ELECTIONS IN EACH STATE
SELECT s.state AS Each_State,
COUNT(cr.parliament_constituency) AS Availabe_Seat
FROM constituencywise_results cr
INNER JOIN
statewise_results sr ON cr.parliament_constituency = sr.parliament_constituency
INNER JOIN
states s ON sr.state_id = s.state_id
GROUP BY s.state
ORDER BY Availabe_Seat DESC


	-- ADD NEW COLUMN FIELD IN TABLE PARTYWISE_RESULTS TO GET THE PARTY ALLIANZ AS NDA, I.N.D.I.A AND OTHER
	ALTER TABLE partywise_results
	ADD Party_coalition varchar(50)

	UPDATE partywise_results
	SET Party_coalition = 'NDA'
	WHERE Party IN
	( 'Bharatiya Janata Party - BJP', 
                'Telugu Desam - TDP', 
				'Janata Dal  (United) - JD(U)',
                'Shiv Sena - SHS', 
                'AJSU Party - AJSUP', 
                'Apna Dal (Soneylal) - ADAL', 
                'Asom Gana Parishad - AGP',
                'Hindustani Awam Morcha (Secular) - HAMS', 
                'Janasena Party - JnP', 
				'Janata Dal  (Secular) - JD(S)',
                'Lok Janshakti Party(Ram Vilas) - LJPRV', 
                'Nationalist Congress Party - NCP',
                'Rashtriya Lok Dal - RLD', 
                'Sikkim Krantikari Morcha - SKM' )

				UPDATE partywise_results
				set party_coalition = 'I.N.D.I.A'
				WHERE PARTY IN 
				( 'Indian National Congress - INC',
                'Aam Aadmi Party - AAAP',
                'All India Trinamool Congress - AITC',
                'Bharat Adivasi Party - BHRTADVSIP',
                'Communist Party of India  (Marxist) - CPI(M)',
                'Communist Party of India  (Marxist-Leninist)  (Liberation) - CPI(ML)(L)',
                'Communist Party of India - CPI',
                'Dravida Munnetra Kazhagam - DMK',
                'Indian Union Muslim League - IUML',
                'Nat`Jammu & Kashmir National Conference - JKN',
                'Jharkhand Mukti Morcha - JMM',
                'Jammu & Kashmir National Conference - JKN',
                'Kerala Congress - KEC',
                'Marumalarchi Dravida Munnetra Kazhagam - MDMK',
                'Nationalist Congress Party Sharadchandra Pawar - NCPSP',
                'Rashtriya Janata Dal - RJD',
                'Rashtriya Loktantrik Party - RLTP',
                'Revolutionary Socialist Party - RSP',
                'Samajwadi Party - SP',
                'Shiv Sena (Uddhav Balasaheb Thackrey) - SHSUBT',
                'Viduthalai Chiruthaigal Katchi - VCK'
)

UPDATE partywise_results
SET party_coalition = 'OTHER'
WHERE party_coalition IS NULL

-- TOTAL SEATS WON BY NDA ALLIANS
SELECT party as party_name,
won as Total_seat_won,
party_coalition
FROM partywise_results
where party_coalition =  'NDA'
order by won  desc

--TOTAL SEATS WON BY I.N.D.I.A. ALLIANS
SELECT party as Party_name,
won as Total_seat_won,
party_coalition
FROM partywise_results
where party_coalition = 'I.N.D.I.A'
order by Total_seat_won desc

--WHICH PARTY ALLIANCE (NDA, I.N.D.I.A, OR OTHER) WON THE MOST SEATS ACROSS ALL STATES
select party_coalition as Party_Name,
sum(won) as Total_seat_won
from partywise_results
group by party_coalition
order by Total_seat_won desc

-- WINNING CANDIDATE'S NAME, THEIR PARTY NAME, TOTAL VOTES, AND THE MARGIN OF VICTORY FOR A SPECIFIC STATE AND CONSTITUENCY
select 
cr.winning_candidate,
pr.party,
cr.Total_votes,
cr.Margin,
s.state,
cr.constituency_name
from constituencywise_results cr
join 
partywise_results pr ON cr.Party_ID = pr.Party_ID
join
statewise_results sr ON cr.Parliament_Constituency = sr.Parliament_Constituency
join 
states s ON sr.State_id = s.state_id
where s.state = 'Gujarat' and cr.constituency_name = 'BHAVNAGAR'

-- WHAT IS THE DISTRIBUTION OF EVM VOTES VERSUS POSTAL VOTES FOR CANDIDATES IN A SPECIFIC CONSTITUENCY
select 
cd.EVM_votes,
cd.Postal_votes,
cr.constituency_name
from constituencywise_details cd
join
constituencywise_results cr on cd.Constituency_ID = cr.Constituency_ID
where cr.constituency_name = 'ALLAHABAD'

--WHICH PARTIES WON THE MOST SEATS IN THE STATE, AND HOW MANY SEATS DID EACH PARTY WIN

select 
pr.party,
count(pr.won) as seat_won
from partywise_results pr
join
constituencywise_results cr on pr.party_id = cr.party_id
join
statewise_results sr on cr.Parliament_Constituency = sr.Parliament_Constituency
group by pr.party
order by count(pr.won) desc


-- WHAT IS THE TOTAL NUMBER OF SEATS WON BY EACH PARTY ALLIANCE (NDA, I.N.D.I.A, AND OTHER) IN EACH STATE FOR THE INDIA ELECTIONS 2024
select 
s.state as State_name,
sum(case when pr.party_coalition = 'NDA' then 1 else 0 end) as NDA_seat_won,
sum(case when pr.party_coalition = 'OTHERS' then 1 else 0 end) as OTHERS_seat_won,
sum(case when pr.party_coalition = 'I.N.D.I.A' then 1 else 0 end) as INDIA_seat_won
from partywise_results pr
join constituencywise_results cr on pr.party_id = cr.party_id
join statewise_results sr on cr.parliament_constituency = sr.parliament_constituency
join states s on sr.state_id = s.state_id
group by s.state
order by s.state

-- WHICH CANDIDATE RECEIVED THE HIGHEST NUMBER OF EVM VOTES IN EACH CONSTITUENCY (TOP 10)

select top 10 
cd.candidate as candidate_name,
cd.EVM_Votes as highest_EVM_Votes,
cr.constituency_name
from constituencywise_details cd
inner join 
constituencywise_results cr on cd.Constituency_ID = cr.Constituency_ID
where cd.EVM_Votes = (
select max(cd1.EVM_Votes)
from constituencywise_details cd1
WHERE cd1.Constituency_ID = cd.Constituency_ID
)
order by cd.EVM_votes desc

--WHICH CANDIDATE WON AND WHICH CANDIDATE WAS THE RUNNER-UP IN EACH CONSTITUENCY OF STATE FOR THE 2024 ELECTIONS
WITH RankedCandidates AS (
    SELECT 
        cd.Constituency_ID,
        cd.Candidate,
        cd.Party,
        cd.EVM_Votes,
        cd.Postal_Votes,
        cd.EVM_Votes + cd.Postal_Votes AS Total_Votes,
        ROW_NUMBER() OVER (PARTITION BY cd.Constituency_ID ORDER BY cd.EVM_Votes + cd.Postal_Votes DESC) AS VoteRank
    FROM 
        constituencywise_details cd
    JOIN 
        constituencywise_results cr ON cd.Constituency_ID = cr.Constituency_ID
    JOIN 
        statewise_results sr ON cr.Parliament_Constituency = sr.Parliament_Constituency
    JOIN 
        states s ON sr.State_ID = s.State_ID
    WHERE 
        s.State = 'Manipur'
)

SELECT 
    cr.Constituency_Name,
    MAX(CASE WHEN rc.VoteRank = 1 THEN rc.Candidate END) AS Winning_Candidate,
    MAX(CASE WHEN rc.VoteRank = 2 THEN rc.Candidate END) AS Runnerup_Candidate
FROM 
    RankedCandidates rc
JOIN 
    constituencywise_results cr ON rc.Constituency_ID = cr.Constituency_ID
GROUP BY 
    cr.Constituency_Name
ORDER BY 
    cr.Constituency_Name

--- FOR THE STATE OF MAHARASHTRA, WHAT ARE THE TOTAL NUMBER OF SEATS, TOTAL NUMBER OF CANDIDATES, 
--TOTAL NUMBER OF PARTIES, TOTAL VOTES (INCLUDING EVM AND POSTAL), AND THE BREAKDOWN OF EVM AND POSTAL VOTES
select 
    count(distinct cr.Constituency_ID) AS Total_Seats,
    count(distinct cd.Candidate) AS Total_Candidates,
    count(distinct p.Party) AS Total_Parties,
    sum(cd.EVM_Votes + cd.Postal_Votes) AS Total_Votes,
    sum(cd.EVM_Votes) AS Total_EVM_Votes,
    sum(cd.Postal_Votes) AS Total_Postal_Votes
from
    constituencywise_results cr
JOIN 
    constituencywise_details cd on cr.Constituency_ID = cd.Constituency_ID
JOIN 
    statewise_results sr on cr.Parliament_Constituency = sr.Parliament_Constituency
JOIN 
    states s on sr.State_ID = s.State_ID
JOIN 
    partywise_results p ON cr.Party_ID = p.Party_ID
WHERE 
    s.State = 'Maharashtra'
