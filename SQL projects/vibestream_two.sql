--- Link to the data base: postgresql://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/vibestream?sslmode=require


/*
Question #1: 
Vibestream is designed for users to share brief updates about 
how they are feeling, as such the platform enforces a character limit of 25. 
How many posts are exactly 25 characters long?

Expected column names: char_limit_posts
*/

-- q1 solution:

select count(*)
from posts
where length(content)=25;


/*

Question #2: 
Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.

Find the difference in the number of posts these two users made on each day 
that at least one of them made a post. Return dates where the absolute value of 
the difference between posts made is greater than 2 
(i.e dates where JamesTiger8285 made at least 3 more posts than RobertMermaid7605 or vice versa).

Expected column names: post_date
*/

-- q2 solution:

with rank_most_post as(select user_id,count(post_id) as num_posts,
row_number() over (order by count(post_id) desc) as ranked_posts
from posts
group by user_id)

,top_active_user as(select user_id,user_name,num_posts
from rank_most_post
join users
using(user_id)
where ranked_posts<3)
select  post_date from(select post_date,count(case when ranked_posts=1 then content end) as p1,
count(case when ranked_posts=2 then content end ) as p2,
ABS(count(case when ranked_posts=1 then content end)-
count(case when ranked_posts=2 then content end)) as postdiff
from posts
join rank_most_post
using(user_id)
where ranked_posts<3
group by 1)sub
where postdiff>2;

/*
Question #3: 
Most users have relatively low engagement and few connections. 
User WilliamEagle6815, for example, has only 2 followers.

Network Analysts would say this user has two **1-step path** relationships. 
Having 2 followers doesn’t mean WilliamEagle6815 is isolated, however. 
Through his followers, he is indirectly connected to the larger Vibestream network.  

Consider all users up to 3 steps away from this user:

- 1-step path (X → WilliamEagle6815)
- 2-step path (Y → X → WilliamEagle6815)
- 3-step path (Z → Y → X → WilliamEagle6815)

Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. 
Order by follower_id and return the top 10 records.

Expected column names: follower_id

*/

-- q3 solution:

SELECT DISTINCT c4.follower_id
from users u
join follows c1 on followee_id=u.user_id
JOIN follows c2 ON c1.follower_id = c2.followee_id
JOIN follows c3 ON c2.follower_id = c3.followee_id
JOIN follows c4 ON c3.follower_id = c4.followee_id
WHERE user_name= 'WilliamEagle6815'
ORDER BY c4.follower_id
limit 10;

/*
Question #4: 
Return top posters for 2023-11-30 and 2023-12-01. 
A top poster is a user who has the most OR second most number of posts 
in a given day. Include the number of posts in the result and 
order the result by post_date and user_id.

Expected column names: post_date, user_id, posts

</aside>
*/

-- q4 solution:

WITH max_posts_user AS (
SELECT
user_id,
post_date,
COUNT(post_id) AS posts,
dense_rank() OVER (PARTITION BY post_date ORDER BY COUNT(post_id) DESC) AS user_ranked
FROM
posts
WHERE
post_date IN ('2023-11-30', '2023-12-01')
GROUP BY
post_date,user_id

)
SELECT
post_date, user_id, posts
from max_posts_user
where user_ranked<3
order by post_date,user_id,posts;

