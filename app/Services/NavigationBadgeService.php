<?php
declare(strict_types=1);
namespace App\Services;

use App\Config\Database;
use PDO;

final class NavigationBadgeService
{
    public static function counts(): array
    {
        $counts=[];
        try {
            $pdo=Database::connection();
            $uid=(int)(Auth::user()['id']??0);
            if (Auth::can('NOTIFICATION_VIEW_OWN')) {
                $counts['notifications']=NotificationService::unread($uid);
            }
            if (Auth::can('LOAD_REVIEW_QUEUE_VIEW')) {
                $counts['loads']=self::scalar($pdo,"SELECT COUNT(*) FROM loads WHERE status='active' AND current_status IN('submitted','under_review','clarification_requested','clarification_received')");
            }
            if (Auth::can('OFFER_QUEUE_VIEW')) {
                $counts['offers']=self::scalar($pdo,"SELECT COUNT(*) FROM bids_offers WHERE status='active' AND offer_status IN('countered','accepted')");
            } elseif (Auth::can('OFFER_VIEW_OWN')) {
                $counts['offers']=self::carrierOffers($pdo,$uid);
            }
            if (Auth::can('SUBSCRIPTION_REVIEW_QUEUE_VIEW')) {
                $counts['subscriptions']=self::scalar($pdo,"SELECT COUNT(*) FROM subscriptions s JOIN verification_cases v ON v.verification_case_id=s.verification_case_id WHERE s.status='active' AND s.subscription_state='requested' AND v.status='pending'");
            }
            if (Auth::can('CARRIER_REVIEW_QUEUE_VIEW')) {
                $counts['carriers']=self::scalar($pdo,"SELECT COUNT(*) FROM truck_owner_profiles WHERE status='active' AND verification_status='pending'");
            }
            if (Auth::can('TRUCK_REVIEW_QUEUE_VIEW')) {
                $counts['trucks']=self::scalar($pdo,"SELECT COUNT(*) FROM trucks WHERE status='active' AND verification_status='pending'");
            }
            if (Auth::can('DRIVER_REVIEW_QUEUE_VIEW')) {
                $counts['drivers']=self::scalar($pdo,"SELECT COUNT(*) FROM drivers WHERE status='active' AND verification_status='pending'");
            }
            if (Auth::can('TRACKING_VIEW_OPERATIONS')) {
                $counts['monitoring']=self::scalar($pdo,"SELECT (SELECT COUNT(*) FROM alerts WHERE status='active' AND alert_status IN('open','acknowledged'))+(SELECT COUNT(*) FROM incidents WHERE status='active' AND incident_status<>'resolved')");
            }
            if (Auth::can('PAYMENT_VIEW_FINANCE')) {
                $counts['payments']=self::scalar($pdo,"SELECT COUNT(*) FROM payments WHERE status='active' AND payment_status IN('requested','submitted')");
            } elseif (Auth::can('PAYMENT_VIEW_SHIPPER')) {
                $companyIds=array_map('intval',array_column(Auth::context()['companies']??[],'company_id'));
                if ($companyIds) {
                    $marks=implode(',',array_fill(0,count($companyIds),'?'));
                    $st=$pdo->prepare("SELECT COUNT(*) FROM payments WHERE status='active' AND payer_company_id IN ($marks) AND payment_status IN('requested','submitted')");
                    $st->execute($companyIds);$counts['payments']=(int)$st->fetchColumn();
                }
            }
        } catch (\Throwable) {
            // Navigation must remain available even when an optional counter cannot be loaded.
        }
        return $counts;
    }

    private static function scalar(PDO $pdo,string $sql): int
    {
        return (int)$pdo->query($sql)->fetchColumn();
    }

    private static function carrierOffers(PDO $pdo,int $uid): int
    {
        $profile=CarrierOnboarding::current($uid);
        if (!$profile) return 0;
        if ($profile['owner_type']==='company') {
            $st=$pdo->prepare("SELECT COUNT(*) FROM bids_offers WHERE status='active' AND carrier_company_id=? AND offer_status IN('sent','countered')");
            $st->execute([(int)$profile['subject_id']]);
        } else {
            $st=$pdo->prepare("SELECT COUNT(*) FROM bids_offers WHERE status='active' AND carrier_user_id=? AND offer_status IN('sent','countered')");
            $st->execute([$uid]);
        }
        return (int)$st->fetchColumn();
    }
}
