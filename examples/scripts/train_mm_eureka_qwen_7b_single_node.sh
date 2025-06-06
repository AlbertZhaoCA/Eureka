set -x
#1)
export RAY_MASTER_PORT=6380
export RAY_DASHBOARD_PORT=8265

OUTPUT_DIR='workspace/MM-EUREKA/output'

export REWARD_LOG_PATH="${OUTPUT_DIR}/reward.log"
export WORKING_DIR=$PWD

#2)---------------------------------------

if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

NODE_RANK=0

#3)-----------------------------------------

if [ "$NODE_RANK" -eq 0 ]; then
    # ray start --head  --port=$RAY_MASTER_PORT --dashboard-host=0.0.0.0 --dashboard-port=$RAY_DASHBOARD_PORT --num-gpus 2
    ray start --head  --port=$RAY_MASTER_PORT --dashboard-host=0.0.0.0 --dashboard-port=$RAY_DASHBOARD_PORT --num-gpus 4
else
    sleep 30
    # ray start --address="$MASTER_ADDR:$RAY_MASTER_PORT" --num-gpus 2 --block
    ray start --address="$MASTER_ADDR:$RAY_MASTER_PORT" --num-gpus 4 --block
fi
sleep 30

#4)------------------------------------------

if [ "$NODE_RANK" -eq 0 ]; then
  RAY_ADDRESS="http://127.0.0.1:$RAY_DASHBOARD_PORT" ray job submit \
  --working-dir $WORKING_DIR \
  -- python3 -m openrlhf.cli.train_ppo_ray \
  --actor_num_nodes 1 \
  --actor_num_gpus_per_node 4 \
  --vllm_num_engines 2 \
  --vllm_tensor_parallel_size 2 \
  --vllm_gpu_memory_utilization 0.7 \
  --vllm_enable_sleep \
  --colocate_all_models \
  --pretrain /home/jovyan/workspace/Qwen \
  --remote_rm_url examples/scripts/reward_func_qwen_instruct.py \
  --save_path ${OUTPUT_DIR} \
  --micro_train_batch_size 2 \
  --train_batch_size 32 \
  --micro_rollout_batch_size 4 \
  --rollout_batch_size 128 \
  --temperature 1.0 \
  --n_samples_per_prompt 8 \
  --max_epochs 1 \
  --max_samples 100000 \
  --num_episodes 1 \
  --prompt_max_len 2048 \
  --generate_max_len 4096 \
  --zero_stage 1 \
  --bf16 \
  --actor_learning_rate 3e-7 \
  --advantage_estimator rloo \
  --init_kl_coef 0.0 \
  --prompt_data /home/jovyan/workspace/dataset/MM-Eureka-Dataset/datasets--FanqingM--MM-Eureka-Dataset/snapshots/88ed7aea8dbb478b7e9fb0607934b5574300cff4/dataset.jsonl \
  --apply_chat_template \
  --disable_fast_tokenizer \
  --normalize_reward \
  --adam_offload \
  --flash_attn \
  --gradient_checkpointing \
  --save_steps 50 \
  --use_tensorboard "${OUTPUT_DIR}/tensorboard" \
  --ckpt_path "${OUTPUT_DIR}/ckpt" \
  --max_ckpt_num 1000000 \
  --save_hf_ckpt \
  --load_checkpoint | tee ${OUTPUT_DIR}/training.log
fi

# --runtime-env-json='{"setup_commands": ["pip install openrlhf[vllm]"]}' [Install deps]
# --ref_reward_offload [Offload to CPU]
# --remote_rm_url http://localhost:5000/get_rewardning.log
fi
