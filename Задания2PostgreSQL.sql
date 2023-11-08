/*Задание 1. Выведите для каждого покупателя его адрес, город и страну проживания.*/
select c.first_name || ' ' ||c.last_name,
       a.address,
       ci.city,
       cr.country 
  from customer c
  join address a on a.address_id = c.address_id 
  join city ci on ci.city_id = a.city_id  
  join country cr on cr.country_id = ci.country_id;

/*Задание 2. С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.*/
 select s.store_id,
        count(c.customer_id ) 
   from store s 
   join customer c on c.store_id = s.store_id 
  group by s.store_id;
 
 /*Доработайте запрос и выведите только те магазины, у которых количество покупателей больше 300. Для решения используйте фильтрацию по сгруппированным строкам с функцией агрегации. 
*/
  select s.store_id,
        count(c.customer_id) 
    from store s 
    join customer c on c.store_id = s.store_id 
   group by s.store_id 
  having count(c.customer_id) > 300;
  
 /*Доработайте запрос, добавив в него информацию о городе магазина, фамилии и имени продавца, который работает в нём. */
   select s.store_id,
          count(c.customer_id),
          ct.city,
          st.first_name,
   		  st.last_name         
    from store s 
    join customer c on c.store_id = s.store_id 
    join staff st on st.staff_id = s.manager_staff_id 
    join address a on a.address_id  = st.address_id 
    join city ct on ct.city_id = a.city_id 
   group by s.store_id, 
   			ct.city ,
   			st.first_name,
   			st.last_name
  having count(c.customer_id) > 300;
  
 /*Задание 3. Выведите топ-5 покупателей, которые взяли в аренду за всё время наибольшее количество фильмов.*/
 select c.first_name || ' ' || c.last_name as customer,
        count(p.payment_id) as payment
   from customer c 
   join payment p on p.customer_id = c.customer_id
  group by c.customer_id
  order by payment desc
 limit 5;
 
/*Задание 4. Посчитайте для каждого покупателя 4 аналитических показателя:
количество взятых в аренду фильмов;
общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа);
минимальное значение платежа за аренду фильма;
максимальное значение платежа за аренду фильма.
*/
select c.first_name || ' ' || c.last_name as customer,
       count(p.payment_id) as count_payment,
       round(sum(p.amount)) as sum_price,
       min(p.amount) as min_price,
       max(p.amount) as max_price
  from customer c 
  join payment p on p.customer_id = c.customer_id
 group by c.customer_id;

/*Задание 5. Используя данные из таблицы городов, составьте одним запросом всевозможные пары городов так, чтобы в результате не было пар с одинаковыми названиями городов. Для решения необходимо использовать декартово произведение.
*/
    select c.city as city1,
    	   c2.city as city2
      from city c 
cross join city c2 
     where c.city != c2.city
     
/*Задание 6. Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и дате возврата (поле return_date), вычислите для каждого покупателя среднее количество дней, за которые он возвращает фильмы.*/
select c.first_name || ' ' || c.last_name as customer,
	   round(avg(date_part('day', return_date - rental_date))) as avg_day
  from rental r 
  join customer c on c.customer_id = r.customer_id 
 group by c.customer_id;

/*Задание 7. Посчитайте для каждого фильма, сколько раз его брали в аренду, а также общую стоимость аренды фильма за всё время.*/
select f.title,
       count(r.rental_id) as count_rental,
       sum(p.amount) as sum_rental
  from rental r  
  join inventory i on r.inventory_id = i.inventory_id 
  join film f on f.film_id = i.film_id 
  join payment p on p.payment_id = r.customer_id 
 group by f.title;
 
/*Задание 8. Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые ни разу не брали в аренду.
*/
select f.title,
       count(r.rental_id) as count_rental,
       sum(p.amount) as sum_rental
  from rental r  
  join inventory i on r.inventory_id = i.inventory_id 
 right join film f on f.film_id = i.film_id 
  join payment p on p.payment_id = r.customer_id 
 group by f.title
having count(r.rental_id) = 0;

/*Задание 9. Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку «Премия». Если количество продаж превышает 7 300, то значение в колонке будет «Да», иначе должно быть значение «Нет».
*/
select s.first_name as staff,
       count(r.rental_id) as sales_for_staff,
       case when count(r.rental_id) > 7300 then 'Да'
            else 'Нет'
       end as Премия
  from staff s 
  join rental r on r.staff_id = s.staff_id 
 group by s.staff_id 
