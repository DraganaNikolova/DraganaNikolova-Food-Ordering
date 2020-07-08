set search_path to foodorder, public;

-- kreirame nova baza vo koja kje ja cuvame arhivskata tabela older orders
create database archive;

-- vo bazata archive kreirame arhivska tabela vo koja kje se cuvaat site naracki
create table older_orders (
    order_id serial primary key,
    person_id int references person(person_id) on delete set null on update cascade,
    distributor_id int references distributor(distributor_id) on delete set null on update cascade,
    total_price int,
    date date
);

-- gji kopirame site dosegashni narachki vo novo kreiranata archivska tabela
-- se upotrebuva dblink bidejki se koristi bazata archive
select
dblink_connect('host=localhost port=5432 user=admin dbname=archive');

select dblink_exec
('
insert into archive.foodorder.older_orders
select *
from dblink(''host=localhost port=5432 user=admin dbname=postgres'', ''SELECT * FROM foodorder.older_orders'') as tb(order_id int, person_id int
    , distributor_id int, total_price int, date date);
');


-- procedura vo koja kje se kopiraat novi podatoci vo arhivskata tabela
-- a od operativnata tabela kje se brisat podatoci postari od 14 dena
create or replace procedure foodorder.moving_orders()
as $$
begin
    -- od operativna vo arhivska se premestuvaat podatoci od poslednite 24 chasa
    -- se uporebuva ekstenzija dblink za da moze da se koristi tabelata older_orders
    -- koja se naogja vo druga baza archive
    perform
    dblink_connect('host=localhost port=5432 user=admin dbname=archive');

    perform dblink_exec
    ('
    insert into archive.foodorder.older_orders
    select *
    from dblink(''host=localhost port=5432 user=admin dbname=postgres'', ''SELECT * FROM foodorder.orders where current_date::date - date <= 1'') as tb(order_id int, person_id int
        , distributor_id int, total_price int, date date);
    ');

    -- se brisat site postari podatoci od 14 dena vo operativnata tabela
    delete from foodorder.orders
    where current_date::date - foodorder.orders.date::date > 14;
end;
$$ language plpgsql;

drop procedure foodorder.moving_orders();
call foodorder.moving_orders();

-- So pomos na Windows Scheduler kreirav nova zadaca koja kje se izvrsuva sekoj den vo 2 casot po polnokj
-- a akcijata koja kje se izvrsuva e povikuvanje na procedurata, toest slednata naredba:
-- "psql -d postgres -U admin&& psql 'call foodorder.moving_orders();'"




