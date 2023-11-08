/*Задания 4*/ 
/*Задание 1. Напишите SQL-запрос, который выводит всю информацию о фильмах со специальным атрибутом (поле special_features) равным “Behind the Scenes”.*/
--EXPLAIN (ANALYZE) actual time=0,261
select *
  from film
 where 'Behind the Scenes' = all(special_features);

/*Задание 2. Напишите ещё 2 варианта поиска фильмов с атрибутом “Behind the Scenes”, используя другие функции или операторы языка SQL для поиска значения в массиве.*/
--EXPLAIN (ANALYZE) actual time=0,403
select * --Если надо вывести ТОЛЬКО 'Behind the Scenes'
  from film
 where special_features[1]='Behind the Scenes'
    or special_features[2]='Behind the Scenes'
    or special_features[3]='Behind the Scenes'
    or special_features[4]='Behind the Scenes'
    or special_features[5]='Behind the Scenes'
    or special_features[6]='Behind the Scenes';
   
--EXPLAIN (ANALYZE) actual time=0,253
select * --Если надо вывести где есть 'Behind the Scenes'
  from film
 where 'Behind the Scenes' = any(special_features);

--EXPLAIN (ANALYZE) actual time=0,332
select * --Если надо вывести где есть 'Behind the Scenes'
  from film
 where special_features && array['Behind the Scenes'];

/*Задание 3. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, помещённый в CTE.*/
--EXPLAIN (ANALYZE) actual time=2,050
with cte as (select film_id
               from film
              where 'Behind the Scenes' = all(special_features))
select r.customer_id,
       count(cte.film_id) as count_film          
  from cte
  join inventory i on i.film_id = cte.film_id
  join rental r on r.inventory_id = i.inventory_id
  group by r.customer_id
  order by r.customer_id;

/*Задание 4. Для каждого покупателя посчитайте, сколько он брал в аренду фильмов со специальным атрибутом “Behind the Scenes”.
Обязательное условие для выполнения задания: используйте запрос из задания 1, помещённый в подзапрос, который необходимо использовать для решения задания.*/
--EXPLAIN (ANALYZE) actual time=2,034
 select r.customer_id,
       count(pod.film_id) as count_film   
  from (select film_id
          from film
         where 'Behind the Scenes' = all(special_features)) pod
  join inventory i on i.film_id = pod.film_id
  join rental r on r.inventory_id = i.inventory_id
 group by r.customer_id
 order by r.customer_id;

/*Задание 5. Создайте материализованное представление с запросом из предыдущего задания и напишите запрос для обновления материализованного представления.*/
create materialized view m_view (customer_id, count_film) as
select r.customer_id,
       count(pod.film_id) as count_film   
  from (select film_id
          from film
         where 'Behind the Scenes' = all(special_features)) pod
  join inventory i on i.film_id = pod.film_id
  join rental r on r.inventory_id = i.inventory_id
 group by r.customer_id
 order by r.customer_id;

select *
  from m_view;
/*обновление материализованного представления.*/
refresh materialized view m_view;

/*Задание 6. С помощью explain analyze проведите анализ скорости выполнения запросов из предыдущих заданий и ответьте на вопросы:
с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания, поиск значения в массиве происходит быстрее;
какой вариант вычислений работает быстрее: с использованием CTE или с использованием подзапроса.*/
/*
1. 
all    - actual time=0,261
[1]    - actual time=0,403 --max
any    - actual time=0,253 --min
array  - actual time=0,332
2.
cte - actual time=2,050 --max
pod - actual time=2,034 --min
*/

/*Задание 7. Используя оконную функцию, выведите для каждого сотрудника сведения о первой его продаже.*/
select distinct staff_id,
       min(rental_date) over (partition by staff_id)
from rental;

/*Задание 8. Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
день, в который арендовали больше всего фильмов (в формате год-месяц-день);
количество фильмов, взятых в аренду в этот день;
день, в который продали фильмов на наименьшую сумму (в формате год-месяц-день);
сумму продажи в этот день.*/
with cte as (select max(count(r.rental_id)) over (partition by st.store_id, to_char(r.rental_date, 'dd.mm.yyyy')) as max_rental_date_count,
					min(sum(p.amount)) over (partition by st.store_id, to_char(r.rental_date, 'dd.mm.yyyy')) as min_rental_date_amount,
                    to_char(r.rental_date, 'dd.mm.yyyy') as date,
                    st.store_id as store_id
               from rental as r
               join staff s on r.staff_id = s.staff_id 
         	   join store st on st.manager_staff_id = s.staff_id
         	   join payment p on p.rental_id = r.rental_id  
         	  group by st.store_id, date)

       select cte1.store_id,
              cte1.date as max_rental_count_date,
              cte1.max_rental_date_count,
              min.date as min_rental_amount_date,
              min.min_rental_date_amount from cte as cte1
    left join cte as cte2 on cte1.store_id = cte2.store_id 
       		  and cte1.max_rental_date_count < cte2.max_rental_date_count
         join (select take1.*
                 from cte as take1
            left join cte as take2 on take1.store_id = take2.store_id
                      and take1.min_rental_date_amount > take2.min_rental_date_amount
                where take2.min_rental_date_amount is null) as min on min.store_id = cte1.store_id
        where cte2.max_rental_date_count is null;