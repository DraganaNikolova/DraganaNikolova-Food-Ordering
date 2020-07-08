set search_path to foodorder, public;

-- vrakja ceni i iminja na 50 random izbrani jadenja
create or replace function foodorder.meal_recipe()
returns table(recipe_id varchar, title varchar, meal_id int, price int, url varchar, chef text, id integer)
LANGUAGE plpgsql
as $$
    begin
        return query
        select r.recipe_id, r.title, m.meal_id, m.price, m.url, e.name || ' ' || e.surname as chefFullName, e.employee_id
        from foodorder.recipe r join foodorder.meal m on r.recipe_id=m.recipe_id
            join foodorder.employee e on e.employee_id = m.chef_id
        order by random();
    end;
$$;

drop function foodorder.meal_recipe();
select * from foodorder.meal_recipe();

-- vrakja meal recipe spored soodveden title
create view foodorder.unique_title
as
    (
    select r1.*
    from recipe r1 join (select title, min(recipe_id) recipe_id
                        from recipe
                        group by title) as r2 on r1.title = r2.title and r2.recipe_id = r1.recipe_id
    );

create view foodorder.unique_recipe
as (
    select r1.*
    from meal r1 join (select recipe_id, min(meal_id) meal_id
                        from meal
                        group by recipe_id) as r2 on r1.recipe_id = r2.recipe_id and r2.meal_id = r1.meal_id
    );

select * from foodorder.unique_title;
--ZA UNIKATNITE SAMO
-- create or replace function foodorder.meal_recipe_search(word varchar)
-- returns table(recipe_id varchar, title varchar, meal_id int, price int, url varchar, chef text, id integer)
-- LANGUAGE plpgsql
-- as $$
--     begin
--         return query
--         select r.recipe_id, r.title, m.meal_id, m.price, m.url, e.name || ' ' || e.surname as chefFullName, e.employee_id
--         from foodorder.unique_title r join foodorder.unique_recipe m on r.recipe_id=m.recipe_id
--             join foodorder.employee e on e.employee_id = m.chef_id
--         where lower(r.title) like '%' || lower(word) || '%';
--     end
-- $$;

create or replace function foodorder.meal_recipe_search(word varchar)
returns table(recipe_id varchar, title varchar, meal_id int, price int, url varchar, chef text, id integer)
LANGUAGE plpgsql
as $$
    begin
        return query
        select distinct r.recipe_id, r.title, m.meal_id, m.price, m.url, e.name || ' ' || e.surname as chefFullName, e.employee_id
        from foodorder.recipe r join foodorder.unique_recipe m on r.recipe_id=m.recipe_id
            join foodorder.employee e on e.employee_id = m.chef_id
        where lower(r.title) like '%' || lower(word) || '%';
    end
$$;
drop function foodorder.meal_recipe_search(word varchar);
select * from foodorder.meal_recipe_search('Peach');

-- vrakja iminja, preziminja, adresi i rating na 12 najdobri chefs
create or replace function foodorder.top_chefs()
returns table(id int, name varchar, surname varchar, rating int)
LANGUAGE plpgsql
as $$
    begin
        return query
        select c.chef_id, e.name, e.surname, c.rating
        from foodorder.chef c join foodorder.employee e on c.chef_id = e.employee_id
        where c.rating > 7 and c.chef_id in (select chef_id
                                             from foodorder.pom)
        order by c.rating desc
        limit 12;
    end;
$$;
drop function top_chefs();
select * from foodorder.top_chefs();


create view foodorder.clients_bad_reviews as (
    select distinct person_id
    from review
    where grade < 7
);

create view foodorder.clients_good_reviews
as (
    select r.person_id
    from review r left join clients_bad_reviews c
        on r.person_id = c.person_id
    where c.person_id is null
   );

-- 5 najcesti klienti so broj na naracki
create or replace function foodorder.top_clients()
returns table(id int, name varchar, surname varchar, total bigint)
LANGUAGE plpgsql
as $$
    begin
        return query
        select p.person_id, p.name, p.surname, co.total
        from foodorder.person p natural join foodorder.count_orders co
        where p.person_id in (select person_id
                              from foodorder.clients_good_reviews)
        order by co.total desc
        limit 5;
    end;
$$;
drop function top_clients();
select * from foodorder.top_clients();

-- 5 najpoznati parovi na jadenja i vkupna nivna suma
create or replace function foodorder.top_meals()
returns table(id1 int, title1 varchar, id2 int, title2 varchar, sum int)
LANGUAGE plpgsql
as $$
    begin
        return query
        select f.first, r1.title, f.second, r2.title, ((m1.price + m2.price)/100.0*90)::numeric::integer
        from foodorder.famous_pairs f join foodorder.meal m1 on f.first = m1.meal_id
                            join foodorder.recipe r1 on m1.recipe_id = r1.recipe_id
                            join foodorder.meal m2 on f.second = m2.meal_id
                            join foodorder.recipe r2 on m2.recipe_id = r2.recipe_id;
    end;
$$;
drop function top_meals();
select * from foodorder.top_meals();

-- za daden recipe_id vrati ingredients
create or replace function foodorder.get_ingredients(id varchar)
returns table(ingredient varchar)
LANGUAGE plpgsql
as $$
    begin
        return query
        select i.ingredient_text
        from foodorder.recipe_ingredient ri join foodorder.ingredient i on ri.ingredient_id = i.ingredient_id
        where ri.recipe_id = id;
    end
$$;

drop function get_ingredients(id varchar);
select * from foodorder.get_ingredients('f4352a99d3b02c4ba774e6880a182dac');

-- vrakja sliki
create or replace function foodorder.get_images()
returns table(img varchar)
LANGUAGE plpgsql
as $$
    begin
        return query
        select url
        from foodorder.meal
        limit 30;
    end
$$;
drop function foodorder.get_images();
select * from foodorder.get_images();

-- DO TUKA
-- vrakja nov mozen package_id
create or replace function foodorder.get_package_id()
returns integer
LANGUAGE plpgsql
as $$
    declare id integer;
    begin
        select max(package_id) + 1 into id
        from foodorder.package;

        insert into foodorder.package values(id, 1);
        return id;
    end
$$;
drop function foodorder.get_package_id();
select * from foodorder.get_package_id();

-- vo soodveten paket se dodava meal_id
create or replace procedure foodorder.add_meal_in_package(package int, meal int)
language plpgsql
as $$
begin
    insert into foodorder.package_meal values (package, meal);

end
$$;
drop procedure foodorder.add_meal_in_package(package integer, meal int);

call foodorder.add_order('Dragana', 'Nikolova', 'Gjorce Petrov',
    10023, 500);

-- se kreira order
create or replace procedure foodorder.add_order(name varchar, surname varchar, address varchar,
 package_id int, price int)
language plpgsql
as $$
    declare clientId int := (select p.person_id
                             from foodorder.person p
                             where p.name = $1 and p.surname = $2 and
                                            p.address = $3);
            orderId int := (select max(order_id) + 1 from foodorder.orders);
            distributorId int := (select distributor_id
                                  from foodorder.distributor
                                  order by random()
                                  limit 1);
            dateOrder date := (select current_date::date);
begin
    if(clientId is null)
    then
    clientId = (select max(person_id) + 1 from foodorder.person);
    insert into foodorder.person values (clientId, $1, $2, $3);
    end if;

    insert into foodorder.orders values (orderId, clientId, distributorId, $5, dateOrder);
    insert into foodorder.package_order values ($4, orderId);

end
$$;
drop procedure add_order();


select max(package_id) + 1 from package;
call add_meal_in_package(10001, 327);
call add_order('Aliai', 'Austin', 'Beverly Hills', 10001, 77);

select *
from orders
order by date desc;

-- se vrakjaat posledno napravenite naracki sortirani po datum
create or replace function foodorder.new_orders()
returns table(name varchar, surname varchar, price int, date varchar)
LANGUAGE plpgsql
as $$
    begin
        return query
        select p.name, p.surname, o.total_price, o.date::varchar
        from foodorder.orders o join foodorder.person p on o.person_id = p.person_id
        order by o.date desc;
    end;
$$;
drop function foodorder.new_orders();
select * from foodorder.new_orders();

-- dodavanje ocenka za kuvar
create or replace procedure add_review(chef int, person int, grading int, com varchar)
language plpgsql
as $$
declare
    -- pomosna promenliva za ID na review
    maxReviewId integer := (select max(review_id)
                            from foodorder.review);
    dateReview date := (select current_date::date);
begin
    if
    (   -- dali klientot koj ostava ocenka za kuvar spored negova hrana ima prethodno naracano takva hrana od toj kuvar
        select count(*)
        from foodorder.orders o join foodorder.package_order po on o.order_id=po.order_id
                      join foodorder.package_meal pm on po.package_id=pm.package_id
                      join foodorder.meal m on pm.meal_id=m.meal_id
        where o.person_id=person and m.chef_id=chef
    ) > 0
        then
        insert into foodorder.review values (maxReviewId+1, chef, person, 1, dateReview, grading, com);
        raise notice 'Values inserted';

        -- promena na rating na kuvarot za koj e ostavena ocenka
        update foodorder.chef
        set rating = (select avg(r.grade)
                      from foodorder.review r
                      where r.chef_id = $1)
        where chef_id = $1;
    end if;
end
$$;

drop procedure add_review( int,  int,  int,  varchar);

-- dali klient ima napraveno naracka od toj kuvar za koj saka da napravi review
create or replace function foodorder.valid_client(person integer, chef integer)
returns boolean
LANGUAGE plpgsql
as $$
    begin
        if
    (   -- dali klientot koj ostava ocenka za kuvar spored negova hrana ima prethodno naracano takva hrana od toj kuvar
        select count(*)
        from foodorder.orders o join foodorder.package_order po on o.order_id=po.order_id
                      join foodorder.package_meal pm on po.package_id=pm.package_id
                      join foodorder.meal m on pm.meal_id=m.meal_id
        where o.person_id=person and m.chef_id=chef
    ) > 0
        then
        return true;
        else
            return false;
    end if;
    end;
$$;
drop function foodorder.valid_client(person integer, chef integer);
select * from foodorder.valid_client();

-- za ime, prezime, adresa vrakja id na klient
create or replace function foodorder.client(name varchar, surname varchar, address varchar)
returns integer
language plpgsql
as $$
    declare clientId int := (select p.person_id
                             from foodorder.person p
                             where p.name = $1 and p.surname = $2 and
                                            p.address = $3);
begin
    if(clientId is null)
    then
    clientId = (select max(person_id) + 1 from foodorder.person);
    insert into foodorder.person values (clientId, $1, $2, $3);
    end if;

    return clientId;
end
$$;

select * from foodorder.client('Dragana', 'Nikolova', 'Gjorce Petrov');

-- se vrakjaat posledno napravenite review sortirani po datum
create or replace function foodorder.new_reviews()
returns table(first varchar, second varchar, name varchar, surname varchar, grade int, comment varchar, date varchar)
LANGUAGE plpgsql
as $$
    begin
        return query
        select e.name, e.surname, p.name, p.surname, r.grade, r.comment, r.date::varchar
        from foodorder.review r join foodorder.person p on r.person_id = p.person_id
            join foodorder.employee e on r.chef_id = e.employee_id
        order by r.date desc
        limit 20;
    end;
$$;
drop function foodorder.new_reviews();
select * from foodorder.new_reviews();