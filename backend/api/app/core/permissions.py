from app.models.user import UserRole


class RoleChecker:
    def __init__(self, allowed_roles: list[UserRole]):
        self.allowed_roles = allowed_roles

    def __call__(self, user_role: UserRole) -> bool:
        return user_role in self.allowed_roles


def check_permission(user_role: UserRole, required_roles: list[UserRole]) -> bool:
    return user_role in required_roles


admin_only = RoleChecker([UserRole.admin])
operations_or_admin = RoleChecker([UserRole.operations, UserRole.admin])
finance_or_admin = RoleChecker([UserRole.finance, UserRole.admin])
branch_manager_or_above = RoleChecker([UserRole.branch_manager, UserRole.operations, UserRole.admin])
