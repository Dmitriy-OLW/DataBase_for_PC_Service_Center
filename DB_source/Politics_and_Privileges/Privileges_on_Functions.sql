-- Отзываем все права на функции у PUBLIC (всех пользователей)
REVOKE ALL ON FUNCTION update_client_status() FROM PUBLIC;
REVOKE ALL ON FUNCTION burn_client_bonuses() FROM PUBLIC;
REVOKE ALL ON FUNCTION transfer_client_to_another_technician(INT, INT, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION calculate_order_cost(INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_receipt_for_order(INT, VARCHAR, DECIMAL) FROM PUBLIC;
REVOKE ALL ON FUNCTION check_part_availability() FROM PUBLIC;
REVOKE ALL ON FUNCTION decrease_part_count() FROM PUBLIC;
REVOKE ALL ON FUNCTION check_booking_availability(INT, DATE, TIME) FROM PUBLIC;
REVOKE ALL ON FUNCTION create_booking_with_check(INT, INT, INT, DATE, TIME) FROM PUBLIC;
REVOKE ALL ON FUNCTION suggest_booking_alternatives(INT, INT, INT, DATE, TIME) FROM PUBLIC;

-- Предоставляем права выполнения только ролям administrator и manager 
GRANT EXECUTE ON FUNCTION update_client_status() TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION burn_client_bonuses() TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION transfer_client_to_another_technician(INT, INT, INT) TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION calculate_order_cost(INT) TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION create_receipt_for_order(INT, VARCHAR, DECIMAL) TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION check_part_availability() TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION decrease_part_count() TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION check_booking_availability(INT, DATE, TIME) TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION create_booking_with_check(INT, INT, INT, DATE, TIME) TO administrator, manager, postgres;
GRANT EXECUTE ON FUNCTION suggest_booking_alternatives(INT, INT, INT, DATE, TIME) TO administrator, manager, postgres;






-- Отзываем все права на функции у PUBLIC (всех пользователей)
REVOKE ALL ON FUNCTION get_bookings_statistics_by_date(DATE, DATE) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_popular_services_stats(DATE, DATE) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_completed_services_stats(DATE, DATE) FROM PUBLIC;

-- Предоставляем права выполнения только ролям administrator и analyst
GRANT EXECUTE ON FUNCTION get_bookings_statistics_by_date(DATE, DATE) TO administrator, analyst, postgres;
GRANT EXECUTE ON FUNCTION get_popular_services_stats(DATE, DATE) TO administrator, analyst, postgres;
GRANT EXECUTE ON FUNCTION get_completed_services_stats(DATE, DATE) TO administrator, analyst, postgres;






