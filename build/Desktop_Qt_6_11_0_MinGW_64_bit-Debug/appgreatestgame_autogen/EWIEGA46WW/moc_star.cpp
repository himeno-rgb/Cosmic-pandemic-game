/****************************************************************************
** Meta object code from reading C++ file 'star.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.11.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../star.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'star.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.11.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN4StarE_t {};
} // unnamed namespace

template <> constexpr inline auto Star::qt_create_metaobjectdata<qt_meta_tag_ZN4StarE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "Star",
        "dataChanged",
        "",
        "nextTurn",
        "infect",
        "addM",
        "bonus",
        "receiveInfection",
        "neighborK",
        "modifyAttribute",
        "attrName",
        "delta",
        "enforceLockdown",
        "p_K",
        "p_N",
        "p_M",
        "p_P",
        "p_Q"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'dataChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'nextTurn'
        QtMocHelpers::MethodData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'infect'
        QtMocHelpers::MethodData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'addM'
        QtMocHelpers::MethodData<void(int)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 6 },
        }}),
        // Method 'receiveInfection'
        QtMocHelpers::MethodData<void(int)>(7, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 8 },
        }}),
        // Method 'modifyAttribute'
        QtMocHelpers::MethodData<void(QString, int)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 10 }, { QMetaType::Int, 11 },
        }}),
        // Method 'enforceLockdown'
        QtMocHelpers::MethodData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'p_K'
        QtMocHelpers::PropertyData<int>(13, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'p_N'
        QtMocHelpers::PropertyData<int>(14, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'p_M'
        QtMocHelpers::PropertyData<int>(15, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'p_P'
        QtMocHelpers::PropertyData<int>(16, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
        // property 'p_Q'
        QtMocHelpers::PropertyData<int>(17, QMetaType::Int, QMC::DefaultPropertyFlags, 0),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<Star, qt_meta_tag_ZN4StarE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject Star::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN4StarE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN4StarE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN4StarE_t>.metaTypes,
    nullptr
} };

void Star::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<Star *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->dataChanged(); break;
        case 1: _t->nextTurn(); break;
        case 2: _t->infect(); break;
        case 3: _t->addM((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 4: _t->receiveInfection((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 5: _t->modifyAttribute((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 6: _t->enforceLockdown(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (Star::*)()>(_a, &Star::dataChanged, 0))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<int*>(_v) = _t->kValue(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->nValue(); break;
        case 2: *reinterpret_cast<int*>(_v) = _t->mValue(); break;
        case 3: *reinterpret_cast<int*>(_v) = _t->pValue(); break;
        case 4: *reinterpret_cast<int*>(_v) = _t->qValue(); break;
        default: break;
        }
    }
}

const QMetaObject *Star::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *Star::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN4StarE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int Star::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 7)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 7;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 7)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 7;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 5;
    }
    return _id;
}

// SIGNAL 0
void Star::dataChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}
QT_WARNING_POP
