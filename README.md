# Food-Ordering
1.
In Entity Relationship Diagram Recipes.jpg is the ERD for my Food Ordering project. The project that I have created is Spring boot + React application, and here are the main SQL files I needed. 
In the ERD we can see that the actual purpose is clients ordering food. An employee can be chef or distributor. Chefs can be employed in a variety of departments, for example restaurants, hotels... Chefs make the meals, and every meal is associated with recipe. Recipe has instruction and ingredients of how it is done. Every meal also has type (salty, sweet, fit, spicy) and category (dessert, main course, salad, fruit) and price. Clients make orders which contain packages. Every package has the meal and quantity of that meal. Clients can also make reviews. Customers leave ratings and comments for cooks who have made the food they previously ordered. The average of all grades for certain chef creates the rating of that chef.

2.
In tables.sql is the actual script for the tables corresponding for the previous ERD model.

3.
Now let us have a look in optimizedQueries.sql. In this file is an example of more complex queries used for the application. 
3.1 The first query has to answer the following question. Which pair of meals most often appear together in a package in the orders? This is used for making appropriate ads and discounts for a pair of meals.
3.2 Names and surnames of the 5 most common clients (those who made the largest number of orders, for one order is considered one prepared meal and not a package) and never left a rating <7. Usage: the best 5 clients will have the opportunity to be rewarded
3.3 10 chefs who have a rating > 7 and have been rated more than 5 times in the last 30 days. Usage: Review at any time for the top 10 chefs

4.
In appProceudures.sql is every stored procedure used for the application.
For example
foodorder.meal_recipe_search(word varchar) is used to find a certain meal containing the word (first parameter) in its title,
foodorder.top_chefs() returns the 12 top chefs.
foodorder.get_ingredients(id varchar) returns the ingredients corresponding for the recipe which id is equal with the first parameter. 
foodorder.add_order(name varchar, surname varchar, address varchar, package_id int, price int) adds new order in the database. 
add_review(chef int, person int, grading int, com varchar) adds new review in the database. 
And so on.

5.
In partitioning.sql the main thing is the procedure foodorder.moving_orders() which moves all new data in the table for archiving and deletes the orders older than 14 days. In the main database we want to keep only the orders for the last 14 days (2 weeks). In another database we have a table that will contain all the orders (history). With Windows Scheduler we create task that executes every day at 2am calling this procedure.
