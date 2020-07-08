set search_path to foodorder, public;

-- 1)
-- Koj par na jadenja najcesto se pojavuvaat zaedno vo paket vo narackite
-- Upotreba: Kreiranja soodvetni reklami i popusti za par na jadenja

-- site parovi na jadenja koi se naracale zaedno
create materialized view pairs
as (
    select p1.package_id, p1.meal_id as first, p2.meal_id as second
    from package_meal p1 join package_meal p2 on p1.package_id = p2.package_id
    where p1.meal_id != p2.meal_id
    group by p1.package_id, p1.meal_id, p2.meal_id
   );

create index pairs_idx on pairs (package_id);

-- pomosen view za kolku pati se pojavil sekoj par na jadenja vo paket
create materialized view pairs_count
as (
    select first, second, count(package_id) total
    from pairs
    group by first, second
   );

create view max_total as (
    select max(total) max
    from pairs_count
);

select * from max_total;

create view famous_pairs
as (
    select first, second
    from pairs_count
    where total = (select max
                   from max_total)
    order by random()
    limit 12
   );
drop view famous_pairs;

select f.first, r1.title, f.second, r2.title
from famous_pairs f join meal m1 on f.first = m1.meal_id join recipe r1 on m1.recipe_id = r1.recipe_id
    join meal m2 on f.second = m2.meal_id join recipe r2 on m2.recipe_id = r2.recipe_id;


-- 2)
-- iminja i preziminja na 5 najcesti klienti (onie koi napravile najgolem broj naracki,
-- za edna naracka se smeta edno izgotveno jadenje a ne paket) a
-- nikogas ne ostavile ocenka < 7
-- Upotreba: najdobrite 5 klienti ke imaat moznost da bidat nagradeni

create temporary table clients_bad_reviews as (
    select distinct person_id
    from review
    where grade < 7
);
drop table clients_bad_reviews;
-- pomosen view za site klienti koi ne ostavile ocenka < 7
create view clients_good_reviews
as (
    select r.person_id
    from review r left join clients_bad_reviews c
        on r.person_id = c.person_id
    where c.person_id is null
   );
select * from clients_good_reviews;
drop view clients_good_reviews;

create index grade_idx on review (person_id, grade);

-- pomosen view za sekoj klient kolku naracki napravil
create materialized view count_orders
as (
    select p.person_id, count(pm.meal_id) total
    from person p join orders o on p.person_id = o.person_id
                  join package_order po on o.order_id = po.order_id
                  join package_meal pm on po.package_id = pm.package_id
    group by p.person_id
   );
select * from count_orders;

create index order_idx on package_order (order_id);
create index person_idx on orders (person_id);

create index total_idx on count_orders(person_id);
drop index total_idx;

select p.person_id, p.name, p.surname, co.total
from person p natural join count_orders co
where p.person_id in (select person_id
                      from clients_good_reviews)
order by co.total desc
limit 5;

-- 3)
-- 10 chefs koi imaat rating > 7, a se oceneti povekje od 5 pati vo poslednite 30 dena
-- Upotreba: Pregled vo sekoe vreme za najdobrite 10 chefs

-- pomosen view za chefs koi se oceneti povekje od 5 pati vo poslednite 30 dena
create view pom
as (
    select chef_id
    from review
    where current_date - date <= 30
    group by chef_id
    having count(grade) > 1
   );
drop view pom;

select e.name, e.surname, c.rating
from chef c join employee e on c.chef_id = e.employee_id
where c.rating > 7 and c.chef_id in (select chef_id
                                     from pom)
order by c.rating desc
limit 10;

create index review_idx on review (date, chef_id, grade);
drop index review_idx; -- ima mnogu inserts vo review zatoa nema da go pravime ovoj indeks
create index rating_idx on chef (rating);

