import telebot
from telebot import types
from database import session, Doctor, Patient  # Импортируем сессии и модель из вашего database.py

bot = telebot.TeleBot('8082732708:AAEvWhwSEzRtilpqXWX8TWlnjJfxXHujHdY')  # Замените на ваш токен

# Состояния для управления процессом
role = None  # Хранит роль пользователя

# Начало работы
@bot.message_handler(commands=['start'])
def start(message):
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn0 = types.KeyboardButton('Информация')
    btn1 = types.KeyboardButton('Выбрать роль')
    markup.add(btn0, btn1)

    bot.send_message(message.chat.id, 'Привет, я медицинский помощник в Telegram. Приступим?', reply_markup=markup)

# Информация
@bot.message_handler(func=lambda message: message.text == 'Информация')
def info(message):
    bot.send_message(message.chat.id, 'Здравствуй, мой дорогой друг! Я — медицинский бот. \n(Описание будет внесено потом)')

# Роль
@bot.message_handler(func=lambda message: message.text == 'Выбрать роль')
def choose_role(message):
    global role  # Используем глобальную переменную для хранения роли
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn2 = types.KeyboardButton('Врач')
    btn3 = types.KeyboardButton('Пациент')
    markup.add(btn2, btn3)

    bot.send_message(message.chat.id, 'Выберите роль:', reply_markup=markup)

    # Регистрация следующего шага
    bot.register_next_step_handler(message, set_role)

def set_role(message):
    global role
    role = message.text  # Сохраняем роль

    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn_create = types.KeyboardButton('Создать профиль')
    btn_login = types.KeyboardButton('Войти в профиль')
    markup.add(btn_create, btn_login)

    bot.send_message(message.chat.id, f'Вы выбрали роль {role}. \nЧто хотите сделать?', reply_markup=markup)
    
    bot.register_next_step_handler(message, handle_profile_option)

def handle_profile_option(message):
    if message.text == 'Создать профиль':
        bot.send_message(message.chat.id, 'Введите логин и пароль для создания профиля:')
        bot.register_next_step_handler(message, create_profile)
    elif message.text == 'Войти в профиль':
        bot.send_message(message.chat.id, 'Введите логин и пароль для входа в профиль:')
        bot.register_next_step_handler(message, login_profile)
    else:
        bot.send_message(message.chat.id, 'Пожалуйста, выберите корректное действие.')
        offer_next_action(message.chat.id)

# Создать профиль доктора
def create_profile(message):
    data = message.text.split()
    if len(data) != 2:
        bot.send_message(message.chat.id, 'Неправильный формат. Введите логин и пароль через пробел:')
        bot.register_next_step_handler(message, create_profile)
        return

    username, password = data

    # Проверка на уникальность логина доктора
    if session.query(Doctor).filter_by(username=username).first():
        bot.send_message(message.chat.id, 'Этот логин уже занят. Попробуйте другой:')
        bot.register_next_step_handler(message, create_profile)
        return

    # Запись в базу данных доктора
    new_user = Doctor(username=username, password=password, role=role.lower())
    session.add(new_user)
    session.commit()

    bot.send_message(message.chat.id, f'Профиль {role.lower()}а создан успешно!')
    commands(message.chat.id)

# Войти в профиль доктора
def login_profile(message):
    data = message.text.split()
    if len(data) != 2:
        bot.send_message(message.chat.id, 'Неправильный формат. Введите логин и пароль через пробел:')
        bot.register_next_step_handler(message, login_profile)
        return

    username, password = data

    user = session.query(Doctor).filter_by(username=username, password=password, role=role.lower()).first()

    if user:
        bot.send_message(message.chat.id, f'Вы успешно вошли в профиль {role.lower()}а!')
        commands(message.chat.id)
    else:
        bot.send_message(message.chat.id, 'Неправильный логин или пароль. Попробуйте снова:')
        offer_next_action(message.chat.id)

#---------------------------------------------------------------------------------------------------------------------------------

# Создать профиль пациента
def create_profile1(message):
    data1 = message.text.split()
    if len(data1) != 2:
        bot.send_message(message.chat.id, 'Неправильный формат. Введите логин и пароль через пробел:')
        bot.register_next_step_handler(message, create_profile1)
        return

    username, password = data1

    # Проверка на уникальность логина пациента
    if session.query(Patient).filter_by(username=username).first():
        bot.send_message(message.chat.id, 'Этот логин уже занят. Попробуйте другой:')
        bot.register_next_step_handler(message, create_profile1)
        return

    # Запись в базу данных пациента
    new_user = Patient(username=username, password=password, role=role.lower())
    session.add(new_user)
    session.commit()

    bot.send_message(message.chat.id, f'Профиль {role.lower()}а создан успешно!')
    commands(message.chat.id)

# Войти в профиль пациента
def login_profile1(message):
    data1 = message.text.split()  # Ожидаем ввод логина и пароля через пробел
    if len(data1) != 2:
        bot.send_message(message.chat.id, 'Неправильный формат. Введите логин и пароль через пробел:')
        bot.register_next_step_handler(message, login_profile1)
        return

    username, password = data1

    user = session.query(Patient).filter_by(username=username, password=password, role=role.lower()).first()

    if user:
        bot.send_message(message.chat.id, f'Вы успешно вошли в профиль {role.lower()}а!')
        commands(message.chat.id)
    else:
        bot.send_message(message.chat.id, 'Неправильный логин или пароль. Попробуйте снова:')
        offer_next_action(message.chat.id)

#Повтор
def offer_next_action(chat_id):
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn_create = types.KeyboardButton('Создать профиль')
    btn_login = types.KeyboardButton('Войти в профиль')
    markup.add(btn_create, btn_login)

    bot.send_message(chat_id, 'Что хотите сделать?', reply_markup=markup)

    # Регистрация следующего шага, чтобы заново обработать выбор пользователя
    bot.register_next_step_handler_by_chat_id(chat_id, handle_profile_option)

# Обработка команд
def commands(chat_id):
    if role == 'Врач':
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
        btn_view = types.KeyboardButton('Открыть список пациентов')
        btn_add = types.KeyboardButton('Добавить пациента')
        markup.add(btn_add, btn_view)
    if role == 'Пациент':
        markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
        btn_doc = types.KeyboardButton('Посмотреть врача')
        btn_bol = types.KeyboardButton('Посмотреть болезнь')
        markup.add(btn_doc, btn_bol)

    bot.send_message(chat_id, 'Выберите дальнейшие действия:', reply_markup=markup)

#Список врачей
@bot.message_handler(func=lambda message: message.text == 'Посмотреть врача')
def handle_view_doctors(message):
    show_doctors(message)

# Показать список врачей для пациента
def show_doctors(message):
    #Поиск всех врачей
    doctors = session.query(Doctor).filter_by(role='врач').all()

    if not doctors:
        bot.send_message(message.chat.id, 'В базе данных пока нет врачей.')
        return

    #Создание списка
    doctor_list = "Список врачей:\n"
    for doctor in doctors:
        doctor_list += f"- {doctor.username} (Role: {doctor.role})\n"

    
    bot.send_message(message.chat.id, doctor_list)



bot.polling(non_stop=True)
