import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/task_model.dart';
import '../views/task/task_form_view.dart';

class TaskCardWidget extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.onComplete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool overdue = task.isOverdue();

    return GestureDetector(
      onTap: () async {
        if (onEdit != null) {
          onEdit!();
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskFormView(task: task)),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: overdue ? AppColors.hpRed.withAlpha(140) : Colors.grey[850]!,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isDone ? Colors.green : AppColors.textSub,
                    width: 2,
                  ),
                  color: task.isDone ? Colors.green : Colors.transparent,
                ),
                child: task.isDone
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: task.isDone
                                ? AppColors.textSub
                                : AppColors.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (task.isDaily)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Hàng ngày",
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: overdue
                                ? AppColors.hpRed
                                : AppColors.textSub,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            overdue ? "${task.time} • Quá hạn" : task.time,
                            style: TextStyle(
                              color: overdue
                                  ? AppColors.hpRed
                                  : AppColors.textSub,
                              fontSize: 13,
                              fontWeight: overdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "+${task.exp} EXP",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "+${task.gold} ",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.orange,
                              size: 11,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (task.isHighPriority)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.hpRed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
