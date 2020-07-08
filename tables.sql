set search_path to foodorder, public;

create table department (
    department_id serial primary key,
    location varchar
);

create table employee (
    employee_id int primary key,
    department_id int references department(department_id) on delete set null on update cascade,
    name varchar,
    surname varchar,
    address varchar,
    manager int references employee(employee_id ) on delete set null on update cascade
);

create table distributor (
    distributor_id int primary key references employee(employee_id) on delete cascade on update cascade
);

create table chef (
    chef_id int primary key references employee(employee_id) on delete cascade on update cascade,
    rating int
);

create table ingredient (
    ingredient_id serial primary key,
    ingredient_text varchar
);

create table instruction (
    instruction_id serial primary key,
    instruction_text varchar
);

create table recipe (
    recipe_id varchar primary key,
    title varchar
);

create table recipe_ingredient (
    recipe_id varchar references recipe(recipe_id) on delete cascade on update cascade,
    ingredient_id int references ingredient(ingredient_id) on delete cascade on update cascade,
    constraint ri_pk primary key (recipe_id, ingredient_id)
);

create table recipe_instruction (
    recipe_id varchar references recipe(recipe_id) on delete cascade on update cascade,
    instruction_id int references instruction(instruction_id) on delete cascade on update cascade,
    constraint ri2_pk primary key (recipe_id, instruction_id)
);

create table category (
    category_id serial primary key,
    description varchar
);

create table type (
    type_id serial primary key,
    description varchar
);

create table meal (
    meal_id serial primary key,
    category_id int references category(category_id) on delete set null on update cascade,
    type_id int references type(type_id) on delete set null on update cascade,
    chef_id int references chef(chef_id) on delete set null on update cascade,
    recipe_id varchar references recipe(recipe_id) on delete set null on update cascade,
    price int
);

create table person (
    person_id int primary key,
    name varchar,
    surname varchar,
    address varchar
);

create table review (
    review_id serial primary key,
    chef_id int references chef(chef_id) on delete set null on update cascade,
    person_id int references person(person_id) on delete set null on update cascade,
    meal_id int references meal(meal_id) on delete set null on update cascade,
    date date,
    grade int check (grade >= 0 and grade <= 10 ),
    comment varchar
);

create table package (
    package_id serial primary key,
    quantity int check ( quantity >= 1 and quantity <= 100 )
);

create table package_meal (
    package_id int references package(package_id) on delete cascade on update cascade,
    meal_id int references meal(meal_id) on delete cascade on update cascade,
    constraint pm_pk primary key (package_id, meal_id)
);

create table orders(
    order_id serial primary key,
    person_id int references person(person_id) on delete set null on update cascade,
    distributor_id int references distributor(distributor_id) on delete set null on update cascade,
    total_price int,
    date date
);


create table package_order (
    package_id serial references package(package_id) on delete cascade on update cascade,
    order_id serial references orders(order_id) on delete cascade on update cascade,
    constraint po_pk primary key (package_id, order_id)
);