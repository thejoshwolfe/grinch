
QT -= core gui

TARGET = grinch
CONFIG += console
CONFIG -= app_bundle

TEMPLATE = app

LIBS += -lsfml-graphics

SOURCES += src/main.cpp \
    src/Entity.cpp

HEADERS += \
    src/Entity.h
