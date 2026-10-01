<?php
declare(strict_types=1);
namespace App\Security;
use App\Config\Database;
use PDO;
final class Authorization {
    public static function load(int $userId): array {
        $pdo=Database::connection();
        $roleSql="SELECT ur.user_role_id,ur.company_id,r.role_id,r.role_code,r.role_name
          FROM user_roles ur JOIN roles r ON r.role_id=ur.role_id
          WHERE ur.user_id=? AND ur.status='active' AND r.is_active=1
          AND ur.effective_from<=UTC_TIMESTAMP(6) AND (ur.effective_to IS NULL OR ur.effective_to>UTC_TIMESTAMP(6))
          ORDER BY r.role_code";
        $st=$pdo->prepare($roleSql); $st->execute([$userId]); $roleRows=$st->fetchAll();
        $permissionSql="SELECT DISTINCT p.permission_code
          FROM user_roles ur JOIN roles r ON r.role_id=ur.role_id
          JOIN role_permissions rp ON rp.role_id=r.role_id AND rp.status='active'
          JOIN permissions p ON p.permission_id=rp.permission_id AND p.is_active=1
          WHERE ur.user_id=? AND ur.status='active' AND r.is_active=1
          AND ur.effective_from<=UTC_TIMESTAMP(6) AND (ur.effective_to IS NULL OR ur.effective_to>UTC_TIMESTAMP(6))
          AND rp.effective_from<=UTC_TIMESTAMP(6) AND (rp.effective_to IS NULL OR rp.effective_to>UTC_TIMESTAMP(6))";
        $st=$pdo->prepare($permissionSql); $st->execute([$userId]); $permissions=$st->fetchAll(PDO::FETCH_COLUMN);
        $companySql="SELECT c.company_id,c.company_ref,c.legal_name,c.display_name,c.verification_status,c.status,
          cm.company_member_id,cm.member_title
          FROM company_members cm JOIN companies c ON c.company_id=cm.company_id
          WHERE cm.user_id=? AND cm.status='active' AND c.status='active'
          AND cm.effective_from<=UTC_TIMESTAMP(6) AND (cm.effective_to IS NULL OR cm.effective_to>UTC_TIMESTAMP(6))
          ORDER BY c.display_name";
        $st=$pdo->prepare($companySql); $st->execute([$userId]); $companies=$st->fetchAll();
        return [
          'roles'=>$roleRows,
          'role_codes'=>array_values(array_unique(array_column($roleRows,'role_code'))),
          'permissions'=>array_values(array_unique($permissions)),
          'companies'=>$companies,
        ];
    }
    public static function can(array $context,string $permission): bool { return in_array($permission,$context['permissions']??[],true); }
}
