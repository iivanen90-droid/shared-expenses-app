# main_shell_feature

Оболонка двох вкладок без бізнес-логіки. Навігацією керує router;
цей пакет відображає NavigationBar і порожні сторінки та отримує callbacks.
Не імпортувати інші feature-пакети. Data/domain/ui-resolver-и залишаються порожніми
до появи погоджених залежностей; не створювати штучні Cubit чи interactor.
Ключі перекладів — common, тема — ui_kit. Інтеграційні тести навігації — mobile/test.
Основні правила: [CLAUDE.md](../../CLAUDE.md).
