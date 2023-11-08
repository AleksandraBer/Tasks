/*Задания 3*/
/*Задание 1. Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
*/
/*Пронумеруйте все платежи от 1 до N по дате*/
select row_number() over(order by p.payment_date),
       p.amount
  from payment p;
/*Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате*/
select row_number() over(partition by p.customer_id order by p.payment_date),
	   p.payment_id 
  from payment p;
/*Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна быть сперва по дате платежа, а затем по сумме платежа от наименьшей к большей*/
select sum(p.amount) over(partition by p.customer_id order by p.payment_date, p.amount asc)
  from payment p;
/*Пронумеруйте платежи для каждого покупателя по стоимости платежа от наибольших к меньшим так, чтобы платежи с одинаковым значением имели одинаковое значение номера.*/
 select p.customer_id,
        dense_rank() over(partition by p.customer_id order by p.amount desc ) as rr,
        p.amount
   from payment p
  order by p.customer_id ;
  
 /*Задание 2. С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате.*/
select customer_id,
       amount,
       lag(amount, 0, 0) over(partition by customer_id order by payment_date)
  from payment;
  
 /*Задание 3. С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.*/
 with cte as(
 		     select payment_date,
 		            sum(amount) as amount
 		       from payment
 		      group by payment_date
 		      order by payment_date),
 	  cte2 as(
 	          select payment_date,
 		             amount,
 		             lag(amount, 1) over(order by payment_date) lag1
 		       from cte)
 		       
select payment_date,
       amount,
       lag1,
       (lag1 - amount) as difference
  from cte2;
 /*Задание 4. С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.*/
select distinct customer_id,
	   max(payment_date) over(partition by customer_id)
  from payment
 order by customer_id
 
 /*Задание 5. С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) с сортировкой по дате.*/
 select s.first_name,
        sum(p.amount) over(partition by s.staff_id order by p.payment_date)
   from staff s
   join payment p on p.staff_id = s.staff_id 
  where to_char(p.payment_date, 'mm.yyyy') = '08.2005';
 
/*Задание 6. 20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей, которые в день проведения акции получили скидку.*/
with cte as (select p.payment_id,
                    row_number() over(order by p.payment_date) rt
               from payment p 
              where to_char(p.payment_date, 'dd.mm.yyyy') = '20.08.2005')
select *
  from cte
 where rt % 100 = 0 

/*Задание 7. Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
покупатель, арендовавший наибольшее количество фильмов;
покупатель, арендовавший фильмов на самую большую сумму;
покупатель, который последним арендовал фильм.*/
with cte as (select cr.customer_id,
		            c.country_id,
                    max(count(r.rental_id)) over(partition by c.country_id, cr.customer_id) as max_count,
                    max(sum(p.amount)) over(partition by c.country_id, cr.customer_id) as max_sum,
                    min(r.rental_date) over(partition by c.country_id, cr.customer_id) as last_rent
               from country c 
               join city ci on ci.country_id = c.country_id 
               join address a on a.city_id = ci.city_id 
               join customer cr on cr.address_id  = a.address_id 
               join rental r on r.customer_id = cr.customer_id  
               join payment p on p.rental_id = r.rental_id 
           group by c.country_id, cr.customer_id, r.rental_date)
           
     select distinct 
            cte1.country_id,
            cte1.max_count,
            cte1.customer_id as max_count_customer,
            max_s.customer_id as max_sum_customer,
            max_s.max_sum,
            last_d.customer_id as last_rent_customer
            
       from cte as cte1     
  left join cte as cte2 on cte1.country_id = cte2.country_id 
	                   and cte1.max_count < cte2.max_count
	   join (select take1.*
	           from cte as take1
	      left join cte as take2 on take1.country_id = take2.country_id
	                            and take1.max_sum < take2.max_sum
	          where take2.max_sum is null) as max_s on max_s.country_id = cte1.country_id
	                  
	   join (select take1.*
	           from cte as take1
	      left join cte as take2 on take1.country_id = take2.country_id
	                            and take1.last_rent > take2.last_rent
	          where take2.last_rent is null) as last_d on last_d.country_id = cte1.country_id
	  where cte2.max_count is null
	  order by country_id;