set -x

export RAY_MASTER_PORT=6379
export RAY_DASHBOARD_PORT=8265
export NCCL_TIMEOUT=7200
NODE_RANK=0  # 或者根据实际情况设置为 1, 2 等
OUTPUT_DIR='workspace/MM-EUREKA/output'

export REWARD_LOG_PATH="${OUTPUT_DIR}/reward.log"
export WORKING_DIR=$PWD


if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

if [ "$NODE_RANK" -eq 0 ]; then
    ray start --head  --port=$RAY_MASTER_PORT --dashboard-host=0.0.0.0 --dashboard-port=$RAY_DASHBOARD_PORT --num-gpus 4
else
    sleep 30
    ray start --address="$MASTER_ADDR:$RAY_MASTER_PORT" --num-gpus 4 --block
fi

sleep 30


if [ "$NODE_RANK" -eq 0 ]; then
  RAY_ADDRESS="http://127.0.0.1:$RAY_DASHBOARD_PORT" ray job submit \
  --working-dir $WORKING_DIR \
  -- python3 -m openrlhf.cli.train_ppo_ray \
  --ref_num_nodes 1 \
  --ref_num_gpus_per_node 4 \
  --remote_rm_url /home/jovyan/workspace/MM-EUREKA/examples/scripts/reward_func_qwen_instruct.py \
  --actor_num_nodes 1 \
  --actor_num_gpus_per_node 4 \
  --vllm_num_engines 4 \
  --vllm_tensor_parallel_size 1 \
  --colocate_all_models \
  --vllm_enable_sleep \
  --vllm_gpu_memory_utilization 0.3 \
  --vllm_sync_backend nccl \
  --pretrain /home/jovyan/workspace/Qwen \
  --save_path ${OUTPUT_DIR} \
  --micro_train_batch_size 2 \
  --train_batch_size 128 \
  --micro_rollout_batch_size 2 \
  --rollout_batch_size 128 \
  --temperature 1.0 \
  --n_samples_per_prompt 8 \
  --lambd 1.0 \
  --gamma 1.0 \
  --max_epochs 1 \
  --num_episodes 10 \
  --prompt_max_len 3000 \
  --max_samples 100000 \
  --generate_max_len 4096 \
  --advantage_estimator group_norm \
  --zero_stage 1 \
  --bf16 \
  --actor_learning_rate 1e-6 \
  --init_kl_coef 0.0 \
  --prompt_data  /home/jovyan/workspace/dataset/ViRL39K/datasets--TIGER-Lab--ViRL39K/snapshots/812ec617dea4bc8a4e751663b88e4ebb7de4d00e/39Krelease.jsonl \
  --disable_fast_tokenizer \
  --input_key message \
  --adam_offload \
  --flash_attn \
  --gradient_checkpointing \
  --save_steps 50 \
  --ckpt_path "${OUTPUT_DIR}/ckpt" \
  --max_ckpt_num 1000000 \
  --save_hf_ckpt \
  --freeze_prefix visual \
  --enable_accuracy_filter \
  --accuracy_lower_bound 0.1 \
  --accuracy_upper_bound 0.9 \
  --use_tensorboard "${OUTPUT_DIR}/tensorboard" \
  --load_checkpoint | tee ${OUTPUT_DIR}/training.log
fi
#  --runtime-env '{"excludes": ["/home/jovyan/workspace/MM-EUREKA/.git/objects/pack/pack-bce8c119b53f857678d1caca96ce153cfd2f699d.pack"]}' \