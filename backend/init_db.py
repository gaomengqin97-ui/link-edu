import sys

from app import app, init_db
from config import Config


def main():
    print(f'数据库连接: {Config.SQLALCHEMY_DATABASE_URI}')
    if not Config.is_mysql():
        print('警告: 当前不是 MySQL 连接，请检查 backend/.env 中的 DATABASE_URL')

    try:
        init_db()
    except Exception as error:
        print('\n数据库初始化失败。')
        print('请确认：')
        print('  1. MySQL 服务已启动（Windows 服务 / Docker）')
        print('  2. 已创建数据库 link（执行 sql/00_create_database.sql）')
        print('  3. backend/.env 中的账号密码正确')
        print(f'\n错误详情: {error}')
        sys.exit(1)

    print('数据库初始化完成，演示账号: demo / link123')


if __name__ == '__main__':
    main()
