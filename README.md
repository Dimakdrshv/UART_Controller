# UART Controller

В данном проекте представлена реализация параметризуемого контроллера UART на языке Verilog HDL.

Данное устройство предназначено для последовательной передачи и приема данных с возможностью настройки скорости передачи, коэффициента семплирования, типа бита четности и количества стоп-битов.

## Содержание

- [Документация](https://github.com/Dimakdrshv/UART_Controller#%D0%B4%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D0%B0%D1%86%D0%B8%D1%8F)
- [Основные возможности](https://github.com/Dimakdrshv/UART_Controller#%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D0%BD%D1%8B%D0%B5-%D0%B2%D0%BE%D0%B7%D0%BC%D0%BE%D0%B6%D0%BD%D0%BE%D1%81%D1%82%D0%B8)
- [Используемые ресурсы](https://github.com/Dimakdrshv/UART_Controller#%D0%B8%D1%81%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D1%83%D0%B5%D0%BC%D1%8B%D0%B5-%D1%80%D0%B5%D1%81%D1%83%D1%80%D1%81%D1%8B)
- [Лицензия](https://github.com/Dimakdrshv/UART_Controller#%D0%BB%D0%B8%D1%86%D0%B5%D0%BD%D0%B7%D0%B8%D1%8F)

## Документация

С документацией работы устройства можно ознакомиться по ссылке: [документация](https://github.com/Dimakdrshv/UART_Controller/wiki/%D0%94%D0%BE%D0%BA%D1%83%D0%BC%D0%B5%D0%BD%D1%82%D0%B0%D1%86%D0%B8%D1%8F).

## Основные возможности

- Настраиваемая скорость передачи данных;
- Поддержка нескольких коэффициентов семплирования;
- Поддержка режимов без бита четности, с odd parity и even parity;
- Поддержка одного или двух стоп-битов;
- Интерфейс взаимодействия на основе AXI4-Stream;
- Комплексное тестирование с использованием Verilog testbench;
- Regression-тестирование различных комбинаций параметров через Tcl-скрипт.

## Используемые ресурсы

Based on general UART protocol materials and FPGA/RTL design practices.

Used for non-commercial educational purposes.

## Лицензия

MIT License.
